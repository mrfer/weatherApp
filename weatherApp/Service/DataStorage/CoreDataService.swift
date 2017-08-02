//
//  CoreDataEngine.swift
//  weatherApp
//
//  Created by Artur on 28.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MapKit

class CoreDataService {
    
    static let sharedInstance: CoreDataService = {
        let instance = CoreDataService()
        return instance
    }()
    
    fileprivate var moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
    fileprivate let fetchRequest = NSFetchRequest<NSFetchRequestResult>()

    init() {
        
        if #available(iOS 10.0, *) {
            moc = CoreDataManager.sharedInstance.persistentContainer.viewContext
        } else {
            moc = CoreDataManager.sharedInstance.managedObjectContext
        }
        
        let entityDescription = NSEntityDescription.entity(forEntityName: "Weather", in: moc)
        fetchRequest.entity = entityDescription
    }
    
    func saveWeather(_ temp: String, _ location: CLLocation) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "Weather", in: moc)
        let weather = Weather(entity:entityDescription!, insertInto: moc)
        
        weather.setValue(temp, forKey: "temp")
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        let timeFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM YYYY"
        timeFormatter.dateFormat = "hh:mm a"
        let dateString = dateFormatter.string(from: currentDate)
        let timeString = timeFormatter.string(from: currentDate)
        weather.setValue(dateString, forKey: "date")
        weather.setValue(timeString, forKey: "time")
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var namePlacemark = String()
            if let placemark = placemarks?[0] {
                if let locationName = placemark.addressDictionary!["City"] as? String {
                    namePlacemark = locationName
                } else if let locationName = placemark.addressDictionary!["Name"] as? String{
                    namePlacemark = locationName
                }
            }
            
            weather.setValue(namePlacemark, forKey: "namePlacemark")
            
            do {
                try self.moc.save()
                NotificationCenter.default.post(name: .weatherAppWillUpateListWeatherNotification, object: nil)
                print("-- Weather Got saved! --")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        })
    }
    
    func saveLastTempCurrentLocation(){
        
        if let lastTempCurrentLocation = WeatherService.sharedManager.lastTempCurrentLocation {
            let lastCurrentLocation = LocationService.sharedManager.lastLocation
            saveWeather(lastTempCurrentLocation, lastCurrentLocation)
        }
    }
    
    func obtainArrayWeathers() -> [WeatherItem]?  {
        
        var result: [NSManagedObject] = []
        
        do {
            result = try moc.fetch(fetchRequest) as! [NSManagedObject]
            if (result.count == 0) {
                print("\n\nData got empty values")
                return nil
            } else {
                
                if result.count > 20 {
                    let countWeathersToRemove = result.count - 20
                    for i in 0..<countWeathersToRemove {
                        removeWeather()
                        result.remove(at: i)
                    }
                }
                
                result.reverse()
                
                return result.map{ dict in
                    
                    let namePlacemark = (dict as AnyObject).value(forKeyPath: "namePlacemark") as? String ?? ""
                    let temp = (dict as AnyObject).value(forKeyPath: "temp") as? String ?? ""
                    let date = (dict as AnyObject).value(forKeyPath: "date") as? String ?? ""
                    let time = (dict as AnyObject).value(forKeyPath: "time") as? String ?? ""
                    
                    return WeatherItem(namePlacemark: namePlacemark, addressPlacemark: nil, temp: temp, date: date, time: time, placemapk: nil)
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
        
    }
    
    func obtainLastWeather() -> Int? {
        
        var result: [NSManagedObject] = []
        
        do {
            result = try moc.fetch(fetchRequest) as! [NSManagedObject]
            if (result.count == 0) {
                print("\n\nData got empty values")
                return nil
            } else {
                
                if result.count > 0 {
                    result.reverse()
                    let temperature = (result[0] as AnyObject).value(forKeyPath: "temp") as? String
                    return Int(temperature!)!
                } else {
                    return nil
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return nil
        }
    }
    
    fileprivate func removeWeather() {
        
        do {
            let result = try moc.fetch(fetchRequest)
            if (result.count == 0) {
                print("There's no weather!")
                return
            }
            
            let managedObject = result.first
            moc.delete(managedObject as! Weather)
            try moc.save()
            print("weather deleted!")
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
}
