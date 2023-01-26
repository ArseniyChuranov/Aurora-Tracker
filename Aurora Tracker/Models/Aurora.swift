//
//  Aurora.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import Foundation

struct Aurora {
    // see what JSON file will provide and extract needed information since for now I'm not sure whet data will I need and use.
    // for now it only gets info for forecast and data, AuroraLocation gets onfo about location of an actual Aurora.
    let observationTime: String
    let forecastTime: String
    var coordinates: [AuroraLocation]? 
    
}

extension Aurora: Identifiable {
    var id: String { observationTime }
}


 
extension Aurora: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case observationTime = "Observation Time"
        case forecastTime = "Forecast Time"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawObservationTime = try? values.decode(String.self, forKey: .observationTime)
        let rawForecastTime = try? values.decode(String.self, forKey: .forecastTime)
        
        guard let observationTime = rawObservationTime,
              let forecastTime = rawForecastTime
        else {
            throw AuroraError.missingData
        }

        self.observationTime = observationTime
        self.forecastTime = forecastTime

    }
    
}

