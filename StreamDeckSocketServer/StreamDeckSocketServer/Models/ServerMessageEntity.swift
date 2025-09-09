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

/// リバーブ変更エンティティ
struct ReverbChangeEntity: Codable {
    let channel: Int
    let reverb: Int
}

/// ディレイ変更エンティティ
struct DelayChangeEntity: Codable {
    let channel: Int
    let delay: Int
}

/// フランジャー変更エンティティ
struct FlangerChangeEntity: Codable {
    let channel: Int
    let flanger: Int
}