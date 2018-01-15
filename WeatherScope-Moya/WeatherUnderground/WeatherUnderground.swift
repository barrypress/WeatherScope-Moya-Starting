/// Copyright (c) 2017 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the \"Software\"), to deal
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
/// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Moya

/// Intermediate endpoint used to map from city names to "zmw" values. Does not use
/// an API key
///
/// - name: THe name of a US city (known to WU, that is)
enum WeatherUndergroundCityAPI {
  case city(name: String)
  // API docs at https://www.wunderground.com/weather/api/d/docs
}

extension WeatherUndergroundCityAPI: Moya.TargetType {
  
  var baseURL: URL {
    return URL(string: "https://autocomplete.wunderground.com")!
  }
  
  var path: String {
    return "/aq"
  }
  
  var method: Moya.Method {
    return .get
  }
  
  var task: Moya.Task {
    switch self {
    case .city(let name):
      return .requestParameters(parameters: ["query": name, "c": "US"],
                                encoding: URLEncoding.queryString)
    }
  }
  
  var sampleData: Data {
    return """
            {"RESULTS" : [{"zmw" : "79101.1.99999", "name" : "Amarillo, Texas"},
                          {"zmw" : "79111.3.99999", "name" : "Amarillo International, Texas"},
                          {"zmw" : "28262.2.99999", "name" : "Amarillo Park, North Carolina"}
                         ]
            }
            """.utf8Encoded
  } 
  
  var  headers: [String : String]? {return ["Content-type": "application/json"]}
} 

/// Forecast endpoint delivering data for WeatherModel
///
/// - zmwForecast: Endpoint given WeatherUnderground-unique "zmw" parameter
/// - zipCurrentForecast: Endpoint given a zip code
/// - locationCurrentForecast: Endpoint given a geocoordinate
enum  WeatherUndergroundAPI {
  case zmwForecast(zmw: String)
  case zipCurrentForecast(zip: String)
  case locationCurrentForecast(lat: Double, lon: Double)
  
  static let APIID = "---yourkeyhere---"
  // Signup at https://www.wunderground.com/signup?mode=api_signup, API docs at https://www.wunderground.com/weather/api/d/docs
} 

extension WeatherUndergroundAPI: Moya.TargetType {
  var baseURL: URL {
    return URL(string: "https://api.wunderground.com/api/\(WeatherUndergroundAPI.APIID)")!
  }
  
  var path: String {
    let suffix: String
    switch self {      
    case .zmwForecast(let zmw):                      suffix = "zmw:\(zmw).json"
    case .zipCurrentForecast(let zip):               suffix = "\(zip).json"
    case .locationCurrentForecast(let lat, let lon): suffix = "\(lat),\(lon).json"
    }
    return "/conditions/q/" + suffix
  }
  
  var method: Moya.Method {
    return .get
  }
  
  var task: Moya.Task {
    return .requestPlain
  }
  
  var headers: [String : String]? {
    return ["Content-type": "application/json"]    
  }
  
  var sampleData: Data {
    return """
            {
              "current_observation" : {
                "weather" : "Clear",
                "relative_humidity" : "27%",
                "temp_f" : 22.600000000000001
              }
            }
            """.utf8Encoded
  }
}
