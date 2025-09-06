//
//  ServerMessageEntity.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation

// MARK: - Server Message Entities

/// ステータス更新エンティティ
struct StatusUpdateEntity: Codable {
    let action: String
    let value: String
    let timestamp: String
}

/// ボリューム変更エンティティ
struct VolumeChangeEntity: Codable {
    let channel: Int
    let volume: Int
}

/// 再生状態エンティティ
struct PlaybackStateEntity: Codable {
    let channel: Int
    let isPlaying: Bool
    let currentTime: Double?
}

/// BPM更新エンティティ
struct BPMUpdateEntity: Codable {
    let channel: Int
    let bpm: Double
    let confidence: Double?
}
