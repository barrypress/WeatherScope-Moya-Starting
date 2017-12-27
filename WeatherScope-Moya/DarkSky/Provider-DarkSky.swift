///// Copyright (c) 2017 Razeware LLC
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

struct DarkSky: WeatherProvider {
  var name = "DarkSky"
  
  let provider = MoyaProvider<DarkSkyAPI>(stubClosure: MoyaProvider.neverStub)
  // testing: (stubClosure: MoyaProvider.immediatelyStub) (stubClosure: MoyaProvider.delayedStub)
  
  func forecast(_ type: RequestType, completion: @escaping (WeatherModel?, String?) -> Void) throws {
    switch type {
    case .location(let lat, let lon):
      let coord = "(\(lat.formatted()), \(lon.formatted()))"
      provider.request(.locationCurrentForecast(lat: lat, lon: lon)) { (result) in
        result.analysis(ifSuccess: {response in self.transform(location: coord, response: response, completion: completion)},
                        ifFailure: {error in completion(nil, error.localizedDescription)})
      }
    default:
      throw ForecastError.requestTypeNotFound
    }
  }
  
  /// Convert a response from the DarkSky API to the standard WeatherModel form. This functionality
  /// is split out from the forecast(_:completion:) function so that if the other RequestType options
  /// can be implemented, then this conversion is readily available should the JSON return be
  /// common
  ///
  /// - Parameters:
  ///   - location: The subject of the forecast (city, zip, or geolocatio)
  ///   - response: The network response (in Alamofire form)
  ///   - completion: The closure to process the finished WeatherModel forecast
  func transform(location: String, response: Response, completion: @escaping (_ result: WeatherModel?, _ error: String?) -> Void) {
    guard let data = try? response.filterSuccessfulStatusCodes().data,
      let fcst = try? JSONDecoder().decode(DSForecast.self, from: data) else {
        let reason = response.statusCode == 404 ? "No forecast available for \"\(location)\""
          : "Network error: \(response.statusCode)"
        completion(nil, reason)
        return
    }
    let model = WeatherModel(source: self.name,
                             location: location,
                             temp: fcst.currently.temperature,
                             humidity: fcst.currently.relativeHumidity,
                             notes: fcst.currently.summary)
    completion(model, nil)
  }
}
