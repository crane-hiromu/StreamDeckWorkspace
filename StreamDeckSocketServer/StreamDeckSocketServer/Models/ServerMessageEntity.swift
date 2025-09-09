//
//  ServerMessageEntity.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation

// MARK: - Server Message Entities

/// ボリューム変更エンティティ
struct VolumeChangeEntity: Codable {
    let channel: Int
    let volume: Int
}