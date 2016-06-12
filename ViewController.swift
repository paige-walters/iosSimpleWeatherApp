//
//  ViewController.swift
//  SimpleWeather
//
//  Created by Joey deVilla on 5/15/16.
//  MIT license. See the end of this file for the gory details.
//
//  Accompanies the article in Global Nerdy (http://globalnerdy.com):
//  "How to build an iOS weather app in Swift, part 5: Putting it all together"
//  http://www.globalnerdy.com/2016/05/16/how-to-build-an-ios-weather-app-in-swift-part-5-putting-it-all-together/
//

import UIKit
import CoreLocation

class ViewController: UIViewController,
                      WeatherGetterDelegate,
                      CLLocationManagerDelegate,
                      UITextFieldDelegate
{
  @IBOutlet weak var cityLabel: UILabel!
  @IBOutlet weak var weatherLabel: UILabel!
  @IBOutlet weak var temperatureLabel: UILabel!
  @IBOutlet weak var cloudCoverLabel: UILabel!
  @IBOutlet weak var windLabel: UILabel!
  @IBOutlet weak var rainLabel: UILabel!
  @IBOutlet weak var humidityLabel: UILabel!
  @IBOutlet weak var getLocationWeatherButton: UIButton!
  @IBOutlet weak var cityTextField: UITextField!
  @IBOutlet weak var getCityWeatherButton: UIButton!
  
  let locationManager = CLLocationManager()
  var weather: WeatherGetter!
  
  
  // MARK: -
  
  override func viewDidLoad() {
    super.viewDidLoad()
    weather = WeatherGetter(delegate: self)
    
    // Initialize UI
    // -------------
    cityLabel.text = "simple weather"
    weatherLabel.text = ""
    temperatureLabel.text = ""
    cloudCoverLabel.text = ""
    windLabel.text = ""
    rainLabel.text = ""
    humidityLabel.text = ""
    cityTextField.text = ""
    cityTextField.placeholder = "Enter city name"
    cityTextField.delegate = self
    cityTextField.enablesReturnKeyAutomatically = true
    getCityWeatherButton.enabled = false
    
    getLocation()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
  // MARK: - Button events and states
  // --------------------------------
  
  @IBAction func getWeatherForLocationButtonTapped(sender: UIButton) {
    setWeatherButtonStates(false)
    getLocation()
  }
  
  @IBAction func getWeatherForCityButtonTapped(sender: UIButton) {
    guard let text = cityTextField.text where !text.trimmed.isEmpty else {
      return
    }
    setWeatherButtonStates(false)
    weather.getWeatherByCity(cityTextField.text!.urlEncoded)
  }
  
  func setWeatherButtonStates(state: Bool) {
    getLocationWeatherButton.enabled = state
    getCityWeatherButton.enabled = state
  }
  

  // MARK: - WeatherGetterDelegate methods
  // -----------------------------------
  
  func didGetWeather(weather: Weather) {
    // This method is called asynchronously, which means it won't execute in the main queue.
    // All UI code needs to execute in the main queue, which is why we're wrapping the code
    // that updates all the labels in a dispatch_async() call.
    dispatch_async(dispatch_get_main_queue()) {
      self.cityLabel.text = weather.city
      self.weatherLabel.text = weather.weatherDescription
      self.temperatureLabel.text = "\(Int(round(weather.tempCelsius)))°"
      self.cloudCoverLabel.text = "\(weather.cloudCover)%"
      self.windLabel.text = "\(weather.windSpeed) m/s"
      
      if let rain = weather.rainfallInLast3Hours {
        self.rainLabel.text = "\(rain) mm"
      }
      else {
        self.rainLabel.text = "None"
      }
      
      self.humidityLabel.text = "\(weather.humidity)%"
      self.getLocationWeatherButton.enabled = true
      self.getCityWeatherButton.enabled = self.cityTextField.text?.characters.count > 0
    }
  }
  
  func didNotGetWeather(error: NSError) {
    // This method is called asynchronously, which means it won't execute in the main queue.
    // All UI code needs to execute in the main queue, which is why we're wrapping the call
    // to showSimpleAlert(title:message:) in a dispatch_async() call.
    dispatch_async(dispatch_get_main_queue()) {
      self.showSimpleAlert(title: "Can't get the weather",
                           message: "The weather service isn't responding.")
      self.getLocationWeatherButton.enabled = true
      self.getCityWeatherButton.enabled = self.cityTextField.text?.characters.count > 0
    }
    print("didNotGetWeather error: \(error)")
  }
  
  
  // MARK: - CLLocationManagerDelegate and related methods
  
  func getLocation() {
    guard CLLocationManager.locationServicesEnabled() else {
      showSimpleAlert(
        title: "Please turn on location services",
        message: "This app needs location services in order to report the weather " +
                 "for your current location.\n" +
                 "Go to Settings → Privacy → Location Services and turn location services on."
      )
      getLocationWeatherButton.enabled = true
      return
    }
    
    let authStatus = CLLocationManager.authorizationStatus()
    guard authStatus == .AuthorizedWhenInUse else {
      switch authStatus {
        case .Denied, .Restricted:
          let alert = UIAlertController(
            title: "Location services for this app are disabled",
            message: "In order to get your current location, please open Settings for this app, choose \"Location\"  and set \"Allow location access\" to \"While Using the App\".",
            preferredStyle: .Alert
          )
          let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
          let openSettingsAction = UIAlertAction(title: "Open Settings", style: .Default) {
            action in
            if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
              UIApplication.sharedApplication().openURL(url)
            }
          }
          alert.addAction(cancelAction)
          alert.addAction(openSettingsAction)
          presentViewController(alert, animated: true, completion: nil)
          getLocationWeatherButton.enabled = true
          return
          
        case .NotDetermined:
          locationManager.requestWhenInUseAuthorization()
          
        default:
          print("Oops! Shouldn't have come this far.")
      }
      
      return
    }
  
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    locationManager.requestLocation()
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    weather.getWeatherByCoordinates(latitude: newLocation.coordinate.latitude,
                                    longitude: newLocation.coordinate.longitude)
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    // This method is called asynchronously, which means it won't execute in the main queue.
    // All UI code needs to execute in the main queue, which is why we're wrapping the call
    // to showSimpleAlert(title:message:) in a dispatch_async() call.
    dispatch_async(dispatch_get_main_queue()) {
      self.showSimpleAlert(title: "Can't determine your location",
                           message: "The GPS and other location services aren't responding.")
    }
    print("locationManager didFailWithError: \(error)")
  }
  
  
  // MARK: - UITextFieldDelegate and related methods
  // -----------------------------------------------
  
  // Enable the "Get weather for the city above" button
  // if the city text field contains any text,
  // disable it otherwise.
  func textField(textField: UITextField,
                 shouldChangeCharactersInRange range: NSRange,
                                               replacementString string: String) -> Bool {
    let currentText = textField.text ?? ""
    let prospectiveText = (currentText as NSString).stringByReplacingCharactersInRange(
      range,
      withString: string).trimmed
    getCityWeatherButton.enabled = prospectiveText.characters.count > 0
    return true
  }
  
  // Pressing the clear button on the text field (the x-in-a-circle button
  // on the right side of the field)
  func textFieldShouldClear(textField: UITextField) -> Bool {
    // Even though pressing the clear button clears the text field,
    // this line is necessary. I'll explain in a later blog post.
    textField.text = ""
    
    getCityWeatherButton.enabled = false
    return true
  }
  
  // Pressing the return button on the keyboard should be like
  // pressing the "Get weather for the city above" button.
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    getWeatherForCityButtonTapped(getCityWeatherButton)
    return true
  }
  
  // Tapping on the view should dismiss the keyboard.
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    view.endEditing(true)
  }
  
  
  // MARK: - Utility methods
  // -----------------------

  func showSimpleAlert(title title: String, message: String) {
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .Alert
    )
    let okAction = UIAlertAction(
      title: "OK",
      style:  .Default,
      handler: nil
    )
    alert.addAction(okAction)
    presentViewController(
      alert,
      animated: true,
      completion: nil
    )
  }
  
}


extension String {
  
  // A handy method for %-encoding strings containing spaces and other
  // characters that need to be converted for use in URLs.
  var urlEncoded: String {
    return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())!
  }
  
  // Trim excess whitespace from the start and end of the string.
  var trimmed: String {
    return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
  }
  
}


// This code is released under the MIT license.
// Simply put, you're free to use this in your own projects, both
// personal and commercial, as long as you include the copyright notice below.
// It would be nice if you mentioned my name somewhere in your documentation
// or credits.
//
// MIT LICENSE
// -----------
// (As defined in https://opensource.org/licenses/MIT)
//
// Copyright © 2016 Joey deVilla. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom
// the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.