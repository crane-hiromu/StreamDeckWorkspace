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

// MARK: - Key Action

protocol KeyEntity {
    var command: CommandType { get }
    var coordinates: KeyCoordinates { get }
}

struct KeyDownEntity: KeyEntity, Codable {
    let command: CommandType
    let sound: String
    let coordinates: KeyCoordinates
}

struct KeyUpEntity: KeyEntity, Codable {
    let command: CommandType
    let coordinates: KeyCoordinates
}

struct LongKeyPressEntity: KeyEntity, Codable {
    let command: CommandType
    let coordinates: KeyCoordinates
}

// MARK: - Dial Action

protocol DialEntity {
    var command: CommandType { get }
}

struct DialRotateEntity: DialEntity, Codable {
    let command: CommandType
    let volume: Int
}

struct DialDownEntity: DialEntity, Codable {
    let command: CommandType
    let volume: Int
}

struct DialUpEntity: DialEntity, Codable {
    let command: CommandType
}

struct LongPressDialUpEntity: DialEntity, Codable {
    let command: CommandType
}

// MARK: - Common Entity

struct KeyCoordinates: Codable {
    let column: Int
    let row: Int
}
