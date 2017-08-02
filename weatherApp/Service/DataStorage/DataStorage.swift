//
//  DataStorage.swift
//  weatherApp
//
//  Created by Artur on 28.07.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation

class DataStorage {
    class var defaultLocalDB: CoreDataService {
        return CoreDataService.sharedInstance
    }
}
