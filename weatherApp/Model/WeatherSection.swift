//
//  WeatherModel.swift
//  weatherApp
//
//  Created by Artur on 28.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import MapKit
import RxDataSources

public struct WeatherSection: AnimatableSectionModelType {
    
    public typealias Item = WeatherItem
    public typealias Identity = String
    
    var header: String
    var storedItems: [Item]
    
    init(header: String, items: [Item]) {
        self.header = header
        self.storedItems = items
    }
    
    public init(original: WeatherSection, items: [Item]) {
        self = original
        self.storedItems = items
    }
    
    public var identity: Identity {
        return header
    }
    
    public var items: [Item] {
        return storedItems
    }
}

public struct WeatherItem {
    
    var namePlacemark: String
    var addressPlacemark: String?
    
    var temp: String?
    var date: String?
    var time: String?
    
    var placemapk: MKPlacemark?
    
}

extension WeatherItem: IdentifiableType, Equatable {
    public typealias Identity = String
    
    public var identity: Identity {
        return namePlacemark
    }
}

public func == (lhs: WeatherItem, rhs: WeatherItem) -> Bool {
    return lhs.namePlacemark == rhs.namePlacemark &&
        (lhs.addressPlacemark == rhs.addressPlacemark) &&
        (lhs.temp == rhs.temp) &&
        (lhs.date == rhs.date) &&
        (lhs.time == rhs.time)
}
