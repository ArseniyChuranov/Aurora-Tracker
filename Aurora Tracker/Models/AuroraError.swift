//
//  AuroraError.swift
//  Aurora Tracker
//
//  Created by Arseniy Churanov on 1/25/23.
//

import Foundation

enum AuroraError: Error {
    case missingData
    case networkError
    case unexpectedError(error: Error)
}

extension AuroraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingData:
            return NSLocalizedString("Found Missing Data.", comment: "missing data")
        case .networkError:
            return NSLocalizedString("Error connecting to network.", comment: "network error")
        case .unexpectedError(let error):
            return NSLocalizedString("Unexpected Error. \(error.localizedDescription)", comment: "unexpected error")
        }
    }
}
