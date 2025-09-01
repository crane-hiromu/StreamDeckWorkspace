//
//  MessageProcessor.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - Message Processor
final class MessageProcessor {

    // MARK: Singleton

    static let shared = MessageProcessor()
    private init() { }

    // MARK: Properties

    private let parser = JSONParser.shared

    // MARK: Methods

    /// 受信したバッファからメッセージを処理する
    /// - Parameters:
    ///   - buffer: 受信データのバッファ
    ///   - bytesRead: 読み取ったバイト数
    func processReceivedMessage(buffer: [UInt8], bytesRead: Int) {
        // 1. Buffer → String
        guard let jsonString = SocketHelper.parseUTF8String(from: buffer, bytesRead: bytesRead) else {
            print("❌ Failed to parse UTF-8 string")
            return
        }
        // 2. String → JSON → Entity
        guard let message = parser.decode(jsonString, as: MessageEntity.self) else {
            print("❌ Failed to parse JSON message: \(jsonString)")
            return
        }
        // 3. メッセージ処理
        handleMessage(message)
    }

    /// メッセージエンティティを処理する
    /// - Parameter message: 処理するメッセージエンティティ
    private func handleMessage(_ entity: MessageEntity) {
        print("📨 Processing message: \(entity)")

        // TODO

        switch entity.action {
        case .keyDown:
            break
        case .keyUp:
            break
        case .longKeyPress:
            break
        case .dialRotate:
            break
        case .dialDown:
            break
        case .dialUp:
            break
        case .longPressDialUp:
            break
        }

        DispatchQueue.main.async {
            SoundPlayer.shared.playSound(named: "puf")
        }
    }
}
