//
//  AuroraOverlay.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/30/23.
//

import MapKit

class AuroraOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    
    
    
    init(coordinate: CLLocationCoordinate2D, boundingMapRect: MKMapRect) {
        self.coordinate = coordinate
        self.boundingMapRect = boundingMapRect
    }
}
