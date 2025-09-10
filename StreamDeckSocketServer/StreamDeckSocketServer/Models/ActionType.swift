//
//  ActionType.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/01.
//

import Foundation

/// アクションのタイプ
enum ActionType: Codable {
    // KeyAction
    case keyDown(KeyDownEntity)
    case keyUp(KeyUpEntity)
    case longKeyPress(LongKeyPressEntity)

    // EncoderAction
    case dialRotate(DialRotateEntity)
    case dialDown(DialDownEntity)
    case dialUp(DialUpEntity)
    case longPressDialUp(LongPressDialUpEntity)

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    // 冗長だがキーのハードコード管理をしたくないので別途enumを設ける
    enum ActionName: String, Codable {
        case keyDown, keyUp, longKeyPress
        case dialRotate, dialDown, dialUp, longPressDialUp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionName.self, forKey: .type)

        switch type {
        case .keyDown:
            let data = try container.decode(KeyDownEntity.self, forKey: .data)
            self = .keyDown(data)
        case .keyUp:
            let data = try container.decode(KeyUpEntity.self, forKey: .data)
            self = .keyUp(data)
        case .longKeyPress:
            let data = try container.decode(LongKeyPressEntity.self, forKey: .data)
            self = .longKeyPress(data)
        case .dialRotate:
            let data = try container.decode(DialRotateEntity.self, forKey: .data)
            self = .dialRotate(data)
        case .dialDown:
            let data = try container.decode(DialDownEntity.self, forKey: .data)
            self = .dialDown(data)
        case .dialUp:
            let data = try container.decode(DialUpEntity.self, forKey: .data)
            self = .dialUp(data)
        case .longPressDialUp:
            let data = try container.decode(LongPressDialUpEntity.self, forKey: .data)
            self = .longPressDialUp(data)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .keyDown(let entity):
            try container.encode(ActionName.keyDown, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .keyUp(let entity):
            try container.encode(ActionName.keyUp, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .longKeyPress(let entity):
            try container.encode(ActionName.longKeyPress, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .dialRotate(let entity):
            try container.encode(ActionName.dialRotate, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .dialDown(let entity):
            try container.encode(ActionName.dialDown, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .dialUp(let entity):
            try container.encode(ActionName.dialUp, forKey: .type)
            try container.encode(entity, forKey: .data)
        case .longPressDialUp(let entity):
            try container.encode(ActionName.longPressDialUp, forKey: .type)
            try container.encode(entity, forKey: .data)
        }
    }
    
    /// アクションに含まれる座標を取得
    var coordinates: KeyCoordinates {
        switch self {
        case .keyDown(let entity):
            return entity.coordinates
        case .keyUp(let entity):
            return entity.coordinates
        case .longKeyPress(let entity):
            return entity.coordinates
        case .dialRotate(let entity):
            return entity.coordinates
        case .dialDown(let entity):
            return entity.coordinates
        case .dialUp(let entity):
            return entity.coordinates
        case .longPressDialUp(let entity):
            return entity.coordinates
        }
    }
}
