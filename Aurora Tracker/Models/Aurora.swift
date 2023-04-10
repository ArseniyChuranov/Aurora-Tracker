//
//  Aurora.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import Foundation

struct Aurora {
    
    // see what JSON file will provide and extract needed information since for now I'm not sure what data will I need.
    // Now this struct decodes all needed info from current source.
    
    let observationTime: String
    let forecastTime: String
    
    // I will use only one decoder here for evertything and for overall simplicity.
    
    var coordinates: [IndividualAuroraSpot]
    
}

extension Aurora: Identifiable {
    var id: String { observationTime } // Should serve as a good unique ID.
}
 
extension Aurora: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case observationTime = "Observation Time"
        case forecastTime = "Forecast Time"
        case coordinates
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(observationTime, forKey: .observationTime)
        try container.encode(forecastTime, forKey: .forecastTime)
        try container.encode(coordinates, forKey: .coordinates)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawObservationTime = try? values.decode(String.self, forKey: .observationTime)
        let rawForecastTime = try? values.decode(String.self, forKey: .forecastTime)
        let rawCoordinates = try? values.decode(Array<Array<Double>>.self, forKey: .coordinates)
        
        guard let observationTime = rawObservationTime,
              let forecastTime = rawForecastTime,
              let coordinates = rawCoordinates
        else {
            throw AuroraError.missingData
        }

        self.observationTime = observationTime
        self.forecastTime = forecastTime
        self.coordinates = coordinates.map { IndividualAuroraSpot(id: UUID(), longitude: $0[0], latitude: $0[1], aurora: $0[2]) } // should work despite looking odd.

    }
    
}

