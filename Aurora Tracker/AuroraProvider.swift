//
//  AuroraProvider.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/26/23.
//

import Foundation

@MainActor
class AuroraProvider: ObservableObject {
    
    // Sample initialization
    @Published var aurora: Aurora = Aurora(observationTime: "2023-01-25T20:01:00Z",
                                           forecastTime: "sample",
                                           coordinates: [IndividualAuroraSpot(longitude: 0, latitude: 0, aurora: 0)])
    
    let client: AuroraClient
    
    func fetchAurora() async throws {
        let latestAurora = try await client.aurora
        self.aurora = latestAurora
        // try await AuroraProvider.save(aurora: latestAurora)
    }
    
    static func load() async throws -> Aurora {
        try await withCheckedThrowingContinuation {continuation in
            load { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let aurora):
                    continuation.resume(returning: aurora)
                }
            }
        }
    }
    
    static func load(completion: @escaping(Result<Aurora, Error>)->Void) {
        
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try! FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
                               .appendingPathComponent("aurora.json")
                
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success(Aurora(observationTime: "Na", forecastTime: "Na", coordinates: [])))
                    }
                    return
                }
                let aurora = try JSONDecoder().decode(Aurora.self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(aurora))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                
            }
        }
    }
    
    private static func fileURL() -> URL {
        try! FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("aurora.data")
    }
    
    @discardableResult
    static func save(aurora: Aurora) async throws -> Int {
        try await withCheckedThrowingContinuation {continuation in
            save(aurora: aurora) {result in
                switch result {
                case .success(let auroraSaved):
                    continuation.resume(returning: auroraSaved)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func save(aurora: Aurora, completion: @escaping (Result<Int, Error>)->Void) {
        DispatchQueue.global(qos: .default).async {
            do {
                let data = try JSONEncoder().encode(aurora)
                
                let outFile = try! FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
                               .appendingPathComponent("aurora.json")
                
                //print("saving?")
                
                try data.write(to: outFile)
                DispatchQueue.main.async {
                    completion(.success(1))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    init(client: AuroraClient = AuroraClient()) {
        self.client = client
    }
}
