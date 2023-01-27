//
//  Aurora+Preview.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import Foundation

extension Aurora {
    static var preview: Aurora {
        let aurora = Aurora(observationTime: "111",
                            forecastTime: "222222",
                            coordinates: [IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -90, aurora: 0),
                                          IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -89, aurora: 0),
                                          IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -88, aurora: 7),
                                          IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -87, aurora: 8),
                                          IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -86, aurora: 8)]
        )
        return aurora
    }
}
