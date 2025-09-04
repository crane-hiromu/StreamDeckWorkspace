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

// MARK: - Base Protocol

protocol BaseEntity {
    var command: CommandType { get }
    var channel: Int { get }
    // var coordinates: KeyCoordinates { get }
    // var isValidCoordinate: Bool { get }
}

extension BaseEntity {
//    // 座標がマイナスの場合は無効
//    var isValidCoordinate: Bool {
//        0 <= coordinates.column || 0 <= coordinates.row
//    }

    var channelType: AdvancedSoundPlayer.Channel {
        .init(rawValue: channel) ?? .other
    }
}

protocol KeyEntity: BaseEntity {}
protocol DialEntity: BaseEntity {}

// MARK: - Key Action

struct KeyDownEntity: KeyEntity, Codable {
    let command: CommandType
    let sound: String?
    let channel: Int
}

struct KeyUpEntity: KeyEntity, Codable {
    let command: CommandType
    let channel: Int
}

struct LongKeyPressEntity: KeyEntity, Codable {
    let command: CommandType
    let channel: Int
}

// MARK: - Dial Action

struct DialRotateEntity: DialEntity, Codable {
    let command: CommandType
    let channel: Int
    let volume: Int?
    let rate: Int?
    let pitch: Int?
    let frequency: Int?
    let delay: Int?
    let reverb: Int?
    let flanger: Int?
}

struct DialDownEntity: DialEntity, Codable {
    let command: CommandType
    let channel: Int
}

struct DialUpEntity: DialEntity, Codable {
    let command: CommandType
    let channel: Int
}

struct LongPressDialUpEntity: DialEntity, Codable {
    let command: CommandType
    let channel: Int
}

// MARK: - Common Entity

struct KeyCoordinates: Codable {
    let column: Int
    let row: Int
}
