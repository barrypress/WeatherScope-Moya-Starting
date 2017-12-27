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

/// The model the WeatherScope-Moya application uses to encapsulate information from network weather
/// sources in a source-independent format used by the user interface
struct WeatherModel {
  /// User-readable name of the network source
  let source: String

  /// Location for which this specific instance is a report
  let location: String
  
  /// Fahrenheit degrees
  let temp: Double
  
  /// Relative humidity, percents (0-100)
  let humidity: Double
  
  /// Readable forecast
  let notes: String?
}

/// Encapsulates the weather forecast request made by the user
///
/// - city: A US city was requested. Strings not classified as location or zip are assumed to be cities
/// - zip: US ZIP-5 format, identified as an integer in the range 0..<10_000
/// - location: A geographic coordinate written as ±lat, ±lon where South latitudes and West longitudes
/// are written with minus signs, and plus signs are typically omitted but may be used.
enum RequestType {
  case city(name: String)
  case zip(zip: String)
  case location(lat: Double, lon: Double)
  
  /// Return a string displaying for the user the type of request
  var stringValue: String {
    switch self {
    case .city: return "City name"
    case .zip: return "Zip code"
    case .location: return "Lat,lon coordinate"
    }
  }
}

/// Identifies objects with the ability to retrieve weather forecasts via Moya to a standard data model
protocol WeatherProvider {
  /// The user-readable name of the Internet data source (e.g., "WeatherUnderground")
  var name: String {get}
  
  /// Access an Internet weather data source for a location identified in a specific way
  ///
  /// - Parameters:
  ///   - type: The form location being identified to the data source
  ///   - completion: Closure executed when the operation completes or fails
  /// - Throws: Throws an error when the operation could not be handled in a way that results in
  /// either a forecast or an expected error. An example is a provider rejecting an instance of
  /// RequestType the provider doesn't support
  func forecast(_ type: RequestType, completion: @escaping (_ result: WeatherModel?, _ error: String?) -> Void) throws
}

/// Errors used to characterize failures related to WeatherProviders
///
/// - requestTypeNotFound: Identifies situations in which the type of RequestType isn't handled by
/// a specific provider instance
/// - networkError: Identifies responses from the network other than those resulting in a valid
/// WeatherModel
enum ForecastError: Error {
  case requestTypeNotFound
  case networkError(code: Int)
}

