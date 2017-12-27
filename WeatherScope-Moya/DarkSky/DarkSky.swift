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

enum DarkSkyAPI {
  case locationCurrentForecast(lat: Double, lon: Double)
  
  static let APIID = "242b64eb600791897d5694c483ef6985"
  // Signup at https://darksky.net/dev, API docs at https://darksky.net/dev/docs
}

extension DarkSkyAPI: Moya.TargetType {
  var baseURL: URL {return URL(string: "https://api.forecast.io/forecast/\(DarkSkyAPI.APIID)/")!}
  
  var path: String {
    switch self {
    case .locationCurrentForecast(let lat, let lon):
      return "\(lat),\(lon)"
    }
  }
  
  var method: Moya.Method {return .get}
  
  var task: Task {return .requestPlain}
  
  var headers: [String : String]? {
    return ["Content-type": "application/json"]
  }
  
  var sampleData: Data {
    return """
            {"currently":{"summary": "Clear",
                          "temperature": 43.11,
                          "dewPoint": 14.02,
                          "humidity": 0.3,
                          "pressure": 1022.4}
            }
            """.utf8Encoded
  }
}
