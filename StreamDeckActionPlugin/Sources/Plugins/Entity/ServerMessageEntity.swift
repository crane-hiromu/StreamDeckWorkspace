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

protocol ServerMessageEntity {}

/// ボリューム変更エンティティ
struct VolumeChangeEntity: Codable, ServerMessageEntity {
    let channel: Int
    let volume: Int
}
