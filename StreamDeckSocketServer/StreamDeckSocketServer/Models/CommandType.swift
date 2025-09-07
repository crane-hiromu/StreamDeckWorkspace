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
    case changeSystemVolume
    case changeChannelVolume
    case changeRate
    case changePitch
    case changeFrequency
    case setLoopState
    case stopSound
    case changeDelay
    case changeReverb
    case changeFlanger
    case scratch
    case scratchWithInertia
    case scratchWithBounce
    case playTone
    case stutter
}
