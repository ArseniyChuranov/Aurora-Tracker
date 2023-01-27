//
//  AuroraProvider.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

@MainActor
class AuroraProvider: ObservableObject {
    
    @Published var aurora: Aurora = Aurora(observationTime: "2023-01-25T20:01:00Z", forecastTime: "sample", coordinates: [IndividualAuroraSpot(longitude: 0, latitude: 0, aurora: 0)])
    
    let client: AuroraClient
    
    func fetchAurora() async throws {
        let latestAurora = try await client.aurora
        self.aurora = latestAurora
    }
    
    init(client: AuroraClient = AuroraClient()) {
        self.client = client
    }
}
