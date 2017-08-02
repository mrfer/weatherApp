//
//  WeatherService.swift
//  weatherApp
//
//  Created by Artur on 30.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications
import MapKit

class WeatherService {
    
    static let sharedManager = WeatherService()
    
    var lastTempCurrentLocation: String?
    
    class func obtainWeatherBackground(_ location: CLLocation){
        
        request(with: location) { valueTemp, errors in
            guard let currentTemp = valueTemp,
               let lastTemp = DataStorage.defaultLocalDB.obtainLastWeather() else { return }
            
            let differenceTemp = Swift.abs(Int(currentTemp)! - lastTemp)
            if  differenceTemp >= 3 {
                LocationService.sharedManager.lastLocation = location
                LocalNotificationService.dispatchlocalNotification(with: differenceTemp)
            }
        }
    }
    
    class func obtainWeatherActiveStatus(with location: CLLocation, _ callback: @escaping (String?, [RequestError]?)-> Void){
        
        request(with: location) { valueTemp, errors in
            if errors != nil {
                callback(nil, errors)
                return
            }

            guard let currentTemp = valueTemp else { return }
            DataStorage.defaultLocalDB.saveWeather(currentTemp, location)
            callback(currentTemp, nil)
        }
    }
    
    fileprivate class func request(with location: CLLocation, _ callback: @escaping (String?, [RequestError]?) -> Void) {
        
        WeatherRequest(latitude: String(location.coordinate.latitude), longitude: String(location.coordinate.longitude)).request { (json, errors) in
            if errors != nil {
                callback(nil, errors)
                return
            }
            
            if let json = json {
                if let mainItems = json["main"].dictionary {
                    if let temp = mainItems["temp"]?.double {
                        
                        let valueTemp = String(Int(temp - 273.15))
                        
                        callback(valueTemp,nil)
                    }
                }
            }
        }
    }
}
