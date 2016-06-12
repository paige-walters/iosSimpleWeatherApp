//
//  WeatherGetter.swift
//  WeatherAppTake3
//
//  Created by Paige Walters on 6/12/16.
//  Copyright © 2016 Paige Walters. All rights reserved.
//

import Foundation

// MARK: WeatherGetterDelegate
// ===========================
// WeatherGetter should be used by a class or struct, and that class or struct
// should adopt this protocol and register itself as the delegate.
// The delegate's didGetWeather method is called if the weather data was
// acquired from OpenWeatherMap.org and successfully converted from JSON into
// a Swift dictionary.
// The delegate's didNotGetWeather method is called if either:
// - The weather was not acquired from OpenWeatherMap.org, or
// - The received weather data could not be converted from JSON into a dictionary.

protocol WeatherGetterDelegate {
    func didGetWeather(weather: Weather)
    func didNotGetWeather(error: NSError)
}

class WeatherGetter {
    
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "e38b40dabc198eff8b5b118da08a86f1"
    
    private var delegate: WeatherGetterDelegate
    
    // MARK: -
    
    init(delegate: WeatherGetterDelegate) {
        self.delegate = delegate
    }
    
    func getWeatherByCity(city: String) {
        let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)")!
        getWeather(weatherRequestURL)
    }
    
    private func getWeather(weatherRequestURL: NSURL) {
        
        // This is a pretty simple networking task, so the shared session will do.
        let session = NSURLSession.sharedSession()
        
        // The data task retrieves the data.
        let dataTask = session.dataTaskWithURL(weatherRequestURL) {
            (data: NSData?, response: NSURLResponse?, error: NSError?) in
            
            
            if let networkError = error {
                // Case 1: Error
                // We got some kind of error while trying to get data from the server.
                self.delegate.didNotGetWeather(networkError)
            }
            else {
                // Case 2: Success
                // We got a response from the server!
                
                do {
                    //Try to conver that data into a Swift Dictionary
                    let weatherData = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! [String: AnyObject]
                    
                    let weather = Weather(weatherData: weatherData)
                    
                    self.delegate.didGetWeather(weather)
                    
                    //If we've made it to this point we've successfully converted the JSON to a swift Dictionary
                }
                catch let jsonError as NSError {
                
                 //An error accord while trying to convert data
                    print("JSON error description: \(jsonError.description)")
                    self.delegate.didNotGetWeather(jsonError)
                }
                
                }
            }
        
        // The data task is set up...launch it!
        dataTask.resume()
    }
}