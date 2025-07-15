//
//  APIError.swift
//  Pocket Poster
//
//  Created by lemin on 7/15/25.
//

import Foundation

enum APIError: LocalizedError {
    // Throw when cannot connect to server
    case connectionFailed
    
    // Throw when it fails to get the repo hash
    case repoHashError
    
    // Throw in all other cases
    case unexpected(info: String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return NSLocalizedString("Could not connect to server", comment: "")
        case .repoHashError:
            return NSLocalizedString("Unable to obtain repo hash. Maybe update to the latest version?", comment: "")
        case .unexpected(let info):
            return info
        }
    }
}
