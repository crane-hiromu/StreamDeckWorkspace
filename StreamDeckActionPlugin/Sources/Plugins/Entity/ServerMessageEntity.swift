//
//  ServerMessageEntity.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation

// MARK: - Server Message Models

/// サーバーからのメッセージを表すエンティティ
struct ServerMessage: Codable {
    let message: ServerMessageType

    init(from decoder: Decoder) throws {
        self.message = try ServerMessageType(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try message.encode(to: encoder)
    }
}

// MARK: - Server Message Entities

protocol ServerMessageEntity {
    var channel: Int { get }
}

/// ボリューム変更エンティティ
struct VolumeChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let volume: Int
}

/// リバーブ変更エンティティ
struct ReverbChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let reverb: Int
}

/// ディレイ変更エンティティ
struct DelayChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let delay: Int
}

/// フランジャー変更エンティティ
struct FlangerChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let flanger: Int
}

/// ピッチ変更エンティティ
struct PitchChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let pitch: Int
}

/// アイソレーター変更エンティティ
struct IsolatorChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let isolator: Int
}
