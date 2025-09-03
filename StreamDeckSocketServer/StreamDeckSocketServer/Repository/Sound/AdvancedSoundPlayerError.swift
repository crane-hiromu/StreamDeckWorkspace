//
//  AdvancedSoundPlayerError.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation

// MARK: - Advanced Sound Player Error
enum AdvancedSoundPlayerError: Int, Error {
    case engineCreationFailed = -1
    case audioFileNotFound = -2
    case audioEngineNotFound = -3

    var localizedDescription: String {
        switch self {
        case .engineCreationFailed:
            return "Failed to create audio engine"
        case .audioFileNotFound:
            return "Audio file not found"
        case .audioEngineNotFound:
            return "Audio engine not found"
        }
    }

    var nsError: NSError {
        NSError(
            domain: "AdvancedSoundPlayer",
            code: rawValue,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
}
