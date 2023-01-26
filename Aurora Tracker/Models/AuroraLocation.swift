//
//  File.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import Foundation

struct AuroraLocation {
    var longitude: [Double]
    var latitude: [Double]
    var aurora: [Double]
}

extension AuroraLocation: Decodable {
    
    private enum coordinatesCodingKeys: String, CodingKey {
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: coordinatesCodingKeys.self)
        let rawCoordinates = try? container.decode(Array<Array<Double>>.self, forKey: .coordinates)
        
        // Maybe it would be smarter to find a way to extract only certain data? like only coordinates with aurora value present
        
        guard let coodrinatesNew = rawCoordinates
        else {
            throw AuroraError.missingData
        }
        
        // This method seems to be inefficient, figure a way to improve in future.
        
        self.longitude = coodrinatesNew.map { $0[0] }
        self.latitude = coodrinatesNew.map { $0[1] }
        self.aurora = coodrinatesNew.map { $0[2] }
        
    }
}
 


