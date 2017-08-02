//
//  WeatherRequest.swift
//  weatherApp
//
//  Created by Irina on 20.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import SwiftyJSON

class WeatherRequest: DFBaseRequest {
    
    init(latitude: String, longitude: String) {
        super.init()
        
        self.parameters = [
            "lat": latitude,
            "lon": longitude,
            "APPID" : "4d20058483f95cc22c6a1a0218b0fb36"
        ]
        
        self.path = "data/2.5/weather"
    }
    
    override func request(_ callback: @escaping (JSON?, [RequestError]?) -> Void) {
        
        self.getRequest(callback)
    }
}
