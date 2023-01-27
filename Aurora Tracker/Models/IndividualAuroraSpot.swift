//
//  IndividualAuroraSpot.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//
//

import Foundation

// this is an individual struct of an aurora with location and indication.

struct IndividualAuroraSpot: Identifiable {
    var id: UUID
    var longitude: Double
    var latitude: Double
    var aurora: Double
    
    init(id: UUID = UUID(), longitude: Double, latitude: Double, aurora: Double) {
        self.id = id
        self.longitude = longitude
        self.latitude = latitude
        self.aurora = aurora
    }
}

