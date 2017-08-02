//
//  WeatherCell.swift
//  weatherApp
//
//  Created by Artur on 30.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import UIKit

class WeatherCell : UITableViewCell {
    
    static let Identifier = "WeatherCell"
    
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var topLabel: UILabel!
    @IBOutlet private var lowerLabel: UILabel!
    @IBOutlet private var tempLabel: UILabel!
    @IBOutlet private var degreesCelsiusLabel: UILabel!
    
    func configureWithWeather(weatherItem: WeatherItem) {
       
        if weatherItem.temp != nil {
            
            iconImageView.image = UIImage(named: "restoreIcon")
            topLabel.text = weatherItem.namePlacemark
            lowerLabel.text = weatherItem.date! + " " + weatherItem.time!
            tempLabel.text = weatherItem.temp
            
            tempLabel.isHidden = false
            degreesCelsiusLabel.isHidden = false
            
        } else {
            
            iconImageView.image = UIImage(named: "pinIcon")
            topLabel.text = weatherItem.namePlacemark
            lowerLabel.text = weatherItem.addressPlacemark
            
            tempLabel.isHidden = true
            degreesCelsiusLabel.isHidden = true
            
        }
    }
}
