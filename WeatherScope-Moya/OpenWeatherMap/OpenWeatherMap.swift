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

enum OpenWeatherMapAPI {
  case cityCurrentForecast(name: String)
  case zipCurrentForecast(cityzip: String)
  case locationCurrentForecast(lat: Double, lon: Double)
  
  static let APIID = "---yourkeyhere---"
  // Signup at https://openweathermap.org/appid, API docs at https://openweathermap.org/api
}

typealias ParameterDictionary = [String: Any]
extension OpenWeatherMapAPI: Moya.TargetType {
  var baseURL: URL {
    return URL(string: "https://api.openweathermap.org/data/2.5")!
  }
  
  var path: String {
    return "/weather"
  }
  
  var method: Moya.Method {
    return .get    
  }
  
  var task: Moya.Task {
    var parms:ParameterDictionary = ["APPID": OpenWeatherMapAPI.APIID, "units": "imperial"]
    switch self {
    case .cityCurrentForecast(let name):
      parms += ["q": name]
    case .zipCurrentForecast(let cityzip):
      parms += ["zip": cityzip]
    case .locationCurrentForecast(let lat, let lon):
      parms += ["lat": lat, "lon": lon]
    }
    return .requestParameters(parameters: parms, encoding: URLEncoding.queryString)
  }
  
  var headers: [String : String]? {return ["Content-type": "application/json"]}
  
  var sampleData: Data {
    return """
            {"weather":[{"main":"Snow",
                        "description":"light snow"},
                        {"main":"Mist",
                         "description":"mist"}],
             "main":{"temp":34.16,
                     "humidity":94},
             "name":"Sandy"}
           """
      .utf8Encoded
  }
}

func += (lhs: inout ParameterDictionary, rhs: ParameterDictionary) {
  for key in rhs.keys {
    lhs[key] = rhs[key]
  }
}
