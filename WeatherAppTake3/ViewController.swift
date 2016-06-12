//
//  ViewController.swift
//  WeatherAppTake3
//
//  Created by Paige Walters on 6/12/16.
//  Copyright © 2016 Paige Walters. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WeatherGetterDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    

    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!

    @IBOutlet weak var getCityWeatherButton: UIButton!
    @IBOutlet weak var cityTextField: UITextField!
    
    var weather: WeatherGetter!
    
    //MARK: -
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    weather = WeatherGetter(delegate: self)
        // Do any additional setup after loading the view, typically from a nib.
        
        cityLabel.text = "simple weather"
        weatherLabel.text = ""
        tempLabel.text = ""
        cloudCoverLabel.text = ""
        windLabel.text = ""
        rainLabel.text = ""
        humidityLabel.text = ""
        cityTextField.text = ""
        cityTextField.placeholder = "Enter city name"
        cityTextField.delegate = self
        cityTextField.enablesReturnKeyAutomatically = true
        getCityWeatherButton.enabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Button events
    
    @IBAction func getWeatherForCityButtonTapped(sender: UIButton) {
        guard let text = cityTextField.text where !text.isEmpty else {
            return
        }
        weather.getWeatherByCity(cityTextField.text!.urlEncoded)
    }
    
    // MARK: -
    
    // MARK: WeatherGetterDelegate methods
    
    func didGetWeather(weather: Weather) {
        dispatch_async(dispatch_get_main_queue()) {
            self.cityLabel.text = weather.city
            self.weatherLabel.text = weather.weatherDescription
            self.tempLabel.text = "\(Int(round(weather.tempFahrenheit)))°"
            self.cloudCoverLabel.text = "\(weather.cloudCover)%"
            self.windLabel.text = "\(weather.windSpeed) m/s"
            self.cityTextField.text = " "
            
            if let rain = weather.rainfallInLast3Hours {
                self.rainLabel.text = "\(rain) mm"
            }
            else {
                self.rainLabel.text = "None"
            }
            
            self.humidityLabel.text = "\(weather.humidity)%"
    }
}

    func didNotGetWeather(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            self.showSimpleAlert(title: "Can't get the weather",
                message: "The weather service isn't responding.")
        }
        print("didNotGetWeather error: \(error)")
}

// MARK: - UITextFieldDelegate and related methods

// Enable the "Get weather for the city above"
// if the city text field contains any text,
// disable it otherwise.

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).stringByReplacingCharactersInRange(range, withString: string)
        getCityWeatherButton.enabled = prospectiveText.characters.count > 0
        print("Count: \(prospectiveText.characters.count)")
        return true
}
// Pressing the clear button on the text field (the x-in-a ciricle button on the right side)
    func textFieldShouldClear(textField: UITextField) -> Bool {
        textField.text = " "
        
        getCityWeatherButton.enabled = false
        return true
    }
    
    //Pressing the return button on the keyboard should be like pressing the "Get weather for the city above" button
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        getWeatherForCityButtonTapped(getCityWeatherButton)
        return true
    }
    
    // Tapping on the view should dismiss the keyboard
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: - Utility Methods
    
    func showSimpleAlert(title title: String, message: String) {
        let alert = UIAlertController(
        title: title, message: message, preferredStyle: .Alert
        )
        let okAction = UIAlertAction(
        title: "OK", style: .Default, handler: nil
        )
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
        
    }
}

extension String {
    
    // A handy method for %-encoding strings containing spaces and other
    // characters that need to be converted for use in URLs.
    
    var urlEncoded: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLUserAllowedCharacterSet())!
    }
}