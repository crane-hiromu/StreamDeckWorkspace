//
//  CommandType.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/01.
//

import Foundation

// MARK: - Command
enum CommandType: Int, Codable {
    case playSound = 0
    case changeVolume = 1
    case changeRate = 2
    case changePitch = 3
    case changeFrequency = 4
    case setLoopState = 5
    case stopSound = 6
}
