//
//  AuroraList+Preview.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

extension AuroraLocationList {
    static var preview: AuroraLocationList {
        let auroraList = AuroraLocationList(id: UUID(),
                                            auroraList: [IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -90, aurora: 0),
                                                         IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -89, aurora: 0),
                                                         IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -88, aurora: 7),
                                                         IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -87, aurora: 8),
                                                         IndividualAuroraSpot(id: UUID(), longitude: 0, latitude: -86, aurora: 8)])
        return auroraList
    }
}
