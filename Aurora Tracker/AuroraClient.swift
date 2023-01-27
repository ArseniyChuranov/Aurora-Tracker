//
//  AuroraClient.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

actor AuroraClient {

    var aurora: Aurora {
        get async throws {
            let data = try await downloader.httpData(from: feedURL)
            let aurora = try decoder.decode(Aurora.self, from: data)
            return aurora
          
            
        }
    }
         
    private lazy var decoder: JSONDecoder = {
        let aDecoder = JSONDecoder()
        aDecoder.dateDecodingStrategy = .millisecondsSince1970
        return aDecoder
    }()
     
    
    private let feedURL = URL(string: "https://services.swpc.noaa.gov/json/ovation_aurora_latest.json")!
    
    private let downloader: any HTTPDataDownloader
    
    init(downloader: any HTTPDataDownloader = URLSession.shared) {
        self.downloader = downloader
    }
}
