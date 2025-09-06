//
//  ServerMessageType.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/07.
//

import Foundation
/// サーバーメッセージのタイプ（ActionTypeパターンに準拠）
enum ServerMessageType: Codable {
    case volumeChange(VolumeChangeEntity)

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    enum MessageName: String, Codable {
        case volumeChange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageName.self, forKey: .type)

        switch type {
        case .volumeChange:
            let data = try container.decode(VolumeChangeEntity.self, forKey: .data)
            self = .volumeChange(data)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .volumeChange(let entity):
            try container.encode(MessageName.volumeChange, forKey: .type)
            try container.encode(entity, forKey: .data)
        }
    }
}
