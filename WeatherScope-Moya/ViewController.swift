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

import UIKit
import Moya

// MARK: - properties and boilerplate
class ViewController: UIViewController {
  var forecasts: [WeatherModel] = []
  
  @IBOutlet weak var query: UITextField!
  @IBOutlet weak var forecastTable: UITableView!
  
  let owm = OpenWeatherMap()
  let ds = DarkSky()
  let wu = WeatherUnderground()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    forecastTable.dataSource = self
    forecastTable.reloadData()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}

// MARK: - Weather model interface
extension ViewController {
  @IBAction func fetchDSForecast(_ sender: UIButton) {
    process(with: ds)
  }
  
  @IBAction func fetchOWMForecast(_ sender: UIButton) {
    process(with: owm)
  }
  
  @IBAction func fetchWU(_ sender: UIButton) {
    process(with: wu)
  }
  
  /// Access the remote API via a Moya provider encapsulated into a WeatherProvider. The
  /// WeatherProvider protocol adds the ability to retrieve a forecast of the type identified
  /// in a RequestType parameter, returning the result in the form of a standardized model (the
  /// WeatherModel type)
  ///
  /// - Parameter provider: One of the known WeatherProviders, which include DarkSky,
  /// OpenWeatherMap, and WeatherUnderground.
  func process(with provider: WeatherProvider) {
    guard let text = query.text, let type = parseRequest(text: text) else {
      userAlert(title: "Query Error",
                message: "Please input a known city (i.e., \"New York\", location (i.e., \"35,-112\"), or zip code (i.e., \"84093\")")
      return
    }
    do {
      try provider.forecast(type) { (model, error) in
        switch (model, error) {
        case (nil, nil):
          break
        case (nil, let error):
          self.userAlert(title: "Error", message: error!)
        case (let model, nil):
          self.forecasts.append(model!)
          self.forecastTable.reloadData()
        default:
          break
        }
      }
      
    } catch {
      userAlert(title: "Forecast", message: "\(type.stringValue) forecasts are not available from \(provider.name)")
    }
  }
  
  /// Determine the kind of request implied by the form of the text supplied by the user, and
  /// use that to create a RequestType object that both defines that type concretely and carries
  /// the associated data in a known format
  ///
  /// - Parameter text: The raw text provide by the user
  /// - Returns: The standardized form of the user request, a RequestType. Nil is returned iff
  /// the type of the input request can't be understood, such as if the request contains no
  /// non-blank text
  func parseRequest(text: String) -> RequestType? {
    let query = text.cleaned
    let coords = query.split(separator: ",").flatMap{Double(String($0).cleaned)}
    if coords.count == 2 {
      return RequestType.location(lat: coords[0], lon: coords[1])
    } else if let val = Int(query), 0..<100_000 ~= val {
      return RequestType.zip(zip: query)
    } else  if !query.isEmpty {
      return RequestType.city(name: query)
    } else {
      return nil
    }
  }
}

// MARK: - UI output
extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return forecasts.count
  }
  
  /// Populate a row in the table view with the result of a network request. Invalid network
  /// requests never reach this point, and all valid requests result in a reply of a standardized
  /// form regardless of source.
  ///
  /// - Parameters:
  ///   - tableView: Standard Apple API, the table being added to
  ///   - indexPath: Standard Apple API, consisting of indices that together represent the path to a
  ///   specific location in a tree of nested arrays. In this application, there are never multiple levels
  /// - Returns: The UITableViewCell the table view uses to display the specified row.
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCellID") else {fatalError("No cell built for table")}
    let row = indexPath.row
    
    let fcst = forecasts[row]
    let hum = fcst.humidity.formatted(decimals: 0)
    var notestext: String = ""
    if let notes = fcst.notes {
      notestext = ", \(notes)"
    }
    cell.textLabel?.font = UIFont(name: "Helvetica", size: 12)
    cell.textLabel?.text = "\(fcst.source)<\(fcst.location)>: \(fcst.temp)°F, \(hum)% RH\(notestext)"
    return cell
  }
}
