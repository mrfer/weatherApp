//
//  LocationService.swift
//  weatherApp
//
//  Created by Artur on 25.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class LocationService: NSObject, CLLocationManagerDelegate {
    
    static let sharedManager = LocationService()
    
    var didUpdateLocation: ((CLLocation) -> Void)?
    
    var lastLocation = CLLocation()
    
    fileprivate var alertIsShown = false
    
    class func startLocation() {
        if (CLLocationManager.locationServicesEnabled()) {
            self.sharedManager.locationManager.delegate = sharedManager
            self.sharedManager.locationManager.startUpdatingLocation()
            print("begin updating location")
        }
    }
    
    class func stopLocation() {
        self.sharedManager.locationManager.stopUpdatingLocation()
        print("did stop location")
    }
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 200.0
        locationManager.activityType = CLActivityType.otherNavigation
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        if #available(iOS 8.0, *) {
            locationManager.requestAlwaysAuthorization()
        }
        
        return locationManager
    }()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if UIApplication.shared.applicationState != .active {
            print("background location : \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            
            if (lastLocation.distance(from: newLocation) >= 200.0) && (WeatherService.sharedManager.lastTempCurrentLocation != nil) {
                WeatherService.obtainWeatherBackground(newLocation)
            }
            
        } else {
            print("active status location:  \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            
            lastLocation = newLocation
            didUpdateLocation?(newLocation)
            
            self.locationManager.stopUpdatingLocation()
            self.locationManager.delegate = nil
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            if alertIsShown == false {
                showAlert()
                alertIsShown = true
            }
        }
    }
    
    fileprivate func showAlert() {
        
        DispatchQueue.main.async(execute: { [unowned self] in
            let message = NSLocalizedString("Доступ к геопозиции запрещен. Приложение работает в ограниченном режиме. Вы можете разрешить доступ в Настройках", comment: "Alert message when the user has denied access")
            let alertController = UIAlertController(title: "weatherApp", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Oк", comment: "Alert OK button"), style: .cancel, handler: {
                action in
                self.alertIsShown = false
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Настройки", comment: "Alert button to open Settings"), style: .default, handler: { action in
                let settingsUrl = NSURL(string:UIApplicationOpenSettingsURLString)
                if let url = settingsUrl {
                    DispatchQueue.main.async {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url as URL)
                        }
                    }
                }
            }))
            self.currentViewController()?.present(alertController, animated: true, completion: nil)
        })
    }
    
    fileprivate func currentViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        if let presentedViewController = rootViewController.presentedViewController{
            return presentedViewController
        }else{
            return rootViewController
        }
    }
}
