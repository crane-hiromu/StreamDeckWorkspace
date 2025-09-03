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

        switch entity.action {
        case .keyDown(let entity):
            switch entity.command {
            case .playSound:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.play(named: entity.sound, on: entity.channelType)
                }
            default:
                break
            }
        case .keyUp:
            break
        case .longKeyPress:
            break
        case .dialRotate(let entity):
            switch entity.command {
            case .playSound:
                break
            case .changeVolume:
                DispatchQueue.main.async {
                    // TODO: これは全体なので音源ごとに調整する場合は別途実装が
                    SystemVolumeManager.shared.adjustVolume(by: (Float(entity.volume ?? 0) / 20.0))
                }
            case .changeRate:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.changeRate(
                        on: entity.channelType,
                        step: entity.rate ?? 0
                    )
                }
            case .changePitch:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.changePitch(
                        on: entity.channelType,
                        step: entity.pitch ?? 0
                    )
                }
            case .changeFrequency:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.setIsolatorBalance(
                        on: entity.channelType,
                        value: Float(entity.frequency ?? 0)
                    )
                }
                break
            }
        case .dialDown(let entity):
            switch entity.command {
            case .playSound:
                break
            case .changeVolume:
                DispatchQueue.main.async {
                    SystemVolumeManager.shared.toggleMute()
                }
            case .changeRate:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetRate(on: entity.channelType)
                }
            case .changePitch:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetPitch(on: entity.channelType)
                }
            case .changeFrequency:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetIsolator(on: entity.channelType)
                }
            }
        case .dialUp:
            break // NOP
        case .longPressDialUp:
            break // NOP
        }
    }
}
