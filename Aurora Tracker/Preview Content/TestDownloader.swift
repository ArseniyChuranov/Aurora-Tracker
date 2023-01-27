//
//  TestDownloader.swift
//  Aurora TrackerTests
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

class TestDownloader: HTTPDataDownloader {
    func httpData(from url: URL) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        return testSample_25012023
    }
}
