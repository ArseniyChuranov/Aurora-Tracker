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
            // save og aurora
            
            createTileDirectory()
            
            let outFile = try! FileManager.default.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: false)
                           .appendingPathComponent("aurora.json")
            
            // save original file
            
            print("data saved")
            
            try data.write(to: outFile)
            
            let aurora = try decoder.decode(Aurora.self, from: data)
            // createTileDirectory()
            //try await AuroraProvider.save(aurora: aurora)
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
    
    func createTileDirectory() {
        
        let documentDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let dirPathTiles = documentDirectory.appendingPathComponent("Tiles")
        
        if !FileManager.default.fileExists(atPath: dirPathTiles!.path()) {
            
            // if directory doesnt exist, create new.
            
            do {
                try FileManager.default.createDirectory(atPath: dirPathTiles!.path() , withIntermediateDirectories: true, attributes: nil)
                print("directory created")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
