//
//  AuroraLocation+Aurora.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.

import Foundation

struct AuroraLocationList: Identifiable {
    var id: UUID
    var auroraList: [IndividualAuroraSpot]
    //it needs to confrom to a RandomAccessElement protocol
    // init it properly, or decode.
}



extension AuroraLocationList: Decodable {
    
    private enum coordinatesCodingKeys: String, CodingKey {
        case coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: coordinatesCodingKeys.self)
        let rawCoordinates = try? container.decode(Array<Array<Double>>.self, forKey: .coordinates) // either change here
        
        // Maybe it would be smarter to find a way to extract only certain data? like only coordinates with aurora value present
        
        guard let coodrinatesNew = rawCoordinates
        else {
            throw AuroraError.missingData
        }
        
        self.id = UUID() // lets see if thats a working solution
        self.auroraList = coodrinatesNew.map { IndividualAuroraSpot(id: UUID(), longitude: $0[0], latitude: $0[1], aurora: $0[2]) }
        // This method seems to be inefficient, figure a way to improve in future.
        // Or here.
        
        /*
        self.longitude = coodrinatesNew.map { $0[0] }
        self.latitude = coodrinatesNew.map { $0[1] }
        self.aurora = coodrinatesNew.map { $0[2] }
         
         */
        
    }
}

