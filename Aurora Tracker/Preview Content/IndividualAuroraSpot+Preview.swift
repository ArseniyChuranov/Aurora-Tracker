//
//  IndividualAuroraSpot+preview.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 4/2/23.
//

import Foundation

extension IndividualAuroraSpot {
    static var preview: [IndividualAuroraSpot] {
        let auroraLocation = AuroraLocation(
        
        var ourputList: [IndividualAuroraSpot] = []
        var index = 0
        
        for item in auroraLocation.aurora {
            let value = IndividualAuroraSpot(longitude: auroraLocation.longitude[index],
                                             latitude: auroraLocation.latitude[index],
                                             aurora: item)
            
            index += 1
            ourputList.append(value)
        }
        
        return ourputList
    }
}