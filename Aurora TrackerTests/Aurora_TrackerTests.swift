//
//  Aurora_TrackerTests.swift
//  Aurora TrackerTests
//
//  Created by Arseniy Churanov on 1/25/23.
//

import XCTest
@testable import Aurora_Tracker

final class Aurora_TrackerTests: XCTestCase {
    
    func testJSONDecoderDecodesData() throws {
        
        // Testing Decoder.
        
        let decoder = JSONDecoder()
        let aurora = try decoder.decode(Aurora.self, from: testSample_25012023)
        
        XCTAssertEqual(aurora.id, "2023-01-25T20:01:00Z")
    }
    
    func testJSONDecoderDecodesDataCoordinates() throws {
        
        // Testing different method for decoding coordinates.
        
        let decoder = JSONDecoder()
        let auroraCoordinates = try decoder.decode(AuroraLocationList.self, from: testSample_25012023)
        
        print(auroraCoordinates.auroraList[0...10])
    }
    
    func testClientDoesFetchAuroraData() async throws {
        
        // Testing Client with test data.
        
        let downloader = TestDownloader()
        let client = AuroraClient(downloader: downloader)
        
        let aurora = try await client.aurora
        
        print(aurora.forecastTime)
    }
     

}
