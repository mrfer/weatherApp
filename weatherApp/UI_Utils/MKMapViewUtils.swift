//
//  MKMapViewUtils.swift
//  weatherApp
//
//  Created by Artur on 30.08.17.
//  Copyright © 2017 Arthur. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
    
    func dropPinZoomIn(with placemark: MKPlacemark){
        
        self.removeAnnotations(self.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        self.addAnnotation(annotation)
        self.setRegionByLocation(placemark.location!)
    }
    
    func setRegionByLocation(_ location: CLLocation){
        
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        self.setRegion(region, animated: true)
        
    }
}
