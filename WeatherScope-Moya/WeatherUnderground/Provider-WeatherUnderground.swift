/// Copyright (c) 2017 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Moya

struct WeatherUnderground: WeatherProvider {
  var name = "WeatherUnderground"
  
  let cityProvider = MoyaProvider<WeatherUndergroundCityAPI>()
  let provider = MoyaProvider<WeatherUndergroundAPI>(stubClosure: MoyaProvider.neverStub)
  // testing: (stubClosure: MoyaProvider.immediatelyStub) (stubClosure: MoyaProvider.delayedStub)
  
  func forecast(_ type: RequestType, completion: @escaping (_ result: WeatherModel?, _ error: String?) -> Void) {
    switch type {
    case .city(let name):
      cityProvider.request(.city(name: name)) { (result)  in
        result.analysis(ifSuccess: {response in self.forecastForCities(response: response, completion: completion)},
                        ifFailure: {error in completion(nil, error.localizedDescription)})
      }
    case .zip(let zip):
      provider.request(.zipCurrentForecast(zip: zip), completion: { (result) in
        result.analysis(ifSuccess: {response in self.transform(location: zip, response: response, completion: completion)},
                        ifFailure: {error in completion(nil, error.localizedDescription)})
      })
    case .location(let lat, let lon):
      let coord = "(\(lat.formatted()), \(lon.formatted()))"
      provider.request(.locationCurrentForecast(lat: lat, lon: lon)) { (result) in
        result.analysis(ifSuccess: {response in self.transform(location: coord, response: response, completion: completion)},
                        ifFailure: {error in completion(nil, error.localizedDescription)})}
    }
  }
  
  /// Generate a WeatherModel for each response to the cities autocomplete API call
  ///
  /// - Parameters:
  ///   - response: Success response from autocomplete
  ///   - completion: Closure to process the finished WeatherModel forecast
  func forecastForCities(response: Response, completion: @escaping (_ result: WeatherModel?, _ error: String?) -> Void) {
    guard let data = try? response.filterSuccessfulStatusCodes().data,
      let auto = try? JSONDecoder().decode(WUACResults.self, from: data),
      auto.RESULTS.count > 0 else {
        completion(nil, response.statusCode == 404
          ? "No forecast available for \"\(name)\""
          : "Network error \"\(response.statusCode)\"")
        return
    }
    for city in auto.RESULTS {
      provider.request(.zmwForecast(zmw: city.zmw)) { result in
        result.analysis(ifSuccess: {response in self.transform(location: city.name, response: response, completion: completion)},
                        ifFailure: {error in completion(nil, error.localizedDescription)})
      }
    }
  }
  
  /// Common creation of stanard WeatherModel instances from WeatherUnderground API responses
  ///
  /// - Parameters:
  ///   - location: Subject of the forecast (city, zip, or geolocatio)
  ///   - response: Network response (in Alamofire form)
  ///   - completion: Closure to process the finished WeatherModel forecast
  func transform(location: String, response: Response, completion: @escaping (_ result: WeatherModel?, _ error: String?) -> Void) {
    guard let data = try? response.filterSuccessfulStatusCodes().data,
      let fcst = try? JSONDecoder().decode(WUForecast.self, from: data) else {
        let reason = response.statusCode == 404 ? "No forecast available for \"\(location)\""
          : "Network error: \(response.statusCode)"
        completion(nil, reason)
        return
    }
    let current = fcst.current_observation
    let notes = current.weather
    let temp = current.temp_f
    let model = WeatherModel(source: self.name,
                             location: location,
                             temp: temp,
                             humidity: Double(current.relative_humidity.dropLast()) ?? 0.0,
                             notes: notes)
    completion(model, nil)
  }
}
