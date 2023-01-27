//
//  HTTPDataDownloader.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

let validStatus = 200...299

protocol HTTPDataDownloader {
    func httpData(from: URL) async throws -> Data
}

extension URLSession: HTTPDataDownloader {
    func httpData(from url: URL) async throws -> Data {
        guard let (data, response) = try await self.data(from: url, delegate: nil) as? (Data, HTTPURLResponse),
              validStatus.contains(response.statusCode) else {
            throw AuroraError.networkError
        }
        return data
    }
}
