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
        let decoder = JSONDecoder()
        let aurora = try decoder.decode(Aurora.self, from: testSample_25012023)
        
        XCTAssertEqual(aurora.id, "2023-01-25T20:01:00Z")
    }
    
    
    
    func testJSONDecoderDecodesDataCoordinates() throws {
        let decoder = JSONDecoder()
        let auroraCoordinates = try decoder.decode(AuroraLocation.self, from: testSample_25012023)
        
        print(auroraCoordinates)
    }
     

}
