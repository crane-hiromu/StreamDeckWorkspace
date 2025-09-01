//
//  MessageEntity.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - Message Entity
/// 受信メッセージを表すエンティティ
struct MessageEntity: Codable {
    let action: ActionType

    init(from decoder: Decoder) throws {
        self.action = try ActionType(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try action.encode(to: encoder)
    }
}

// MARK: - Action Specific Entities
struct KeyDownEntity: Codable {
    let command: CommandType
}

struct KeyUpEntity: Codable {}

struct LongKeyPressEntity: Codable {}

struct DialRotateEntity: Codable {}

struct DialDownEntity: Codable {}

struct DialUpEntity: Codable {}

struct LongPressDialUpEntity: Codable {}

// MARK: - Command
enum CommandType: Int, Codable {
    case playSound = 0
}
