//
//  LocalNotificationService.swift
//  weatherApp
//
//  Created by Artur on 30.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class LocalNotificationService: NSObject, UNUserNotificationCenterDelegate {
    
    class func registerForLocalNotification(on application:UIApplication) {
        if (UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:)))) {
            let notificationCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
            notificationCategory.identifier = "NOTIFICATION_CATEGORY"
            
            //registerting for the notification.
            application.registerUserNotificationSettings(UIUserNotificationSettings(types:[.sound, .alert, .badge], categories: nil))
        }
    }
    
    class func dispatchlocalNotification(with valueTemp: Int, userInfo: [AnyHashable: Any]? = nil) {
        
        if #available(iOS 10.0, *) {
            
            removeNotifications(withIdentifiers: ["myNotification"])
            
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Изменение температуры"
            content.body = "Температура изменилась на " + outputCorrectionDegreeСelsius(valueTemp)
            content.categoryIdentifier = "Fechou"
            
            if let info = userInfo {
                content.userInfo = info
            }
            
            content.sound = UNNotificationSound.default()
            
            let request = UNNotificationRequest(identifier: "myNotification", content: content, trigger: nil)
            
            center.add(request)
            
        } else {
            
            let notification = UILocalNotification()
            notification.alertTitle = "Изменение температуры"
            notification.alertBody = "Температура изменилась на " + outputCorrectionDegreeСelsius(valueTemp)
            
            if let info = userInfo {
                notification.userInfo = info
            }
            
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.scheduleLocalNotification(notification)
            
        }
        
        print("LOCAL NOTIFICATION")
    }
    
    fileprivate class func outputCorrectionDegreeСelsius(_ temp: Int) -> String {
        
        if temp < 5 {
            return String(temp) + "градуса"
        } else {
            return String(temp) + "градусов"
        }
    }
    
    @available(iOS 10.0, *)
    fileprivate class func removeNotifications(withIdentifiers identifiers: [String]){
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
