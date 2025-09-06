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
                    AdvancedSoundPlayer.shared.play(
                        named: entity.sound ?? "",
                        on: entity.channelType
                    )
                }
            case .playTone:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.playTone(
                        entity.note ?? "C",
                        on: entity.channelType
                    )
                }
            case .setLoopState:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.toggleLoop(on: entity.channelType)
                }
            case .stopSound:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.stop(entity.channelType)
                }
            case .changeVolume,
                 .changeRate,
                 .changePitch,
                 .changeFrequency,
                 .changeDelay,
                 .changeReverb,
                 .changeFlanger,
                 .scratch,
                 .scratchWithInertia,
                 .scratchWithBounce: break
            case .stutter:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.startStutter(
                        on: entity.channelType,
                        segmentLength: entity.stutterSegmentLength ?? 0.25
                    )
                }
            }
        case .keyUp:
            break
        case .longKeyPress:
            break
        case .dialRotate(let entity):
            switch entity.command {
            case .changeVolume:
                DispatchQueue.main.async {
                    // TODO: これは全体なので音源ごとに調整する場合は別途実装が
                    SystemVolumeManager.shared.adjustVolume(
                        by: (Float(entity.volume ?? 0) / 20.0)
                    )
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
            case .changeDelay:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.changeDelayMix(
                        on: entity.channelType,
                        step: entity.delay ?? 0
                    )
                }
            case .changeReverb:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.changeReverbWetDryMix(
                        on: entity.channelType,
                        step: entity.reverb ?? 0
                    )
                }
            case .changeFlanger:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.changeFlangerWetDryMix(
                        on: entity.channelType,
                        step: entity.flanger ?? 0
                    )
                }
            case .scratch:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.startScratch(
                        on: entity.channelType,
                        value: entity.scratch ?? 0
                    )
                }
            case .scratchWithInertia:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.scratchWithInertia(
                        on: entity.channelType,
                        value: entity.scratch ?? 0,
                        sensitivity: entity.scratchSensitivity ?? 1.0
                    )
                }
            case .scratchWithBounce:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.scratchWithBounce(
                        on: entity.channelType,
                        value: entity.scratch ?? 0
                    )
                }
            case .stutter:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.updateStutterSegmentLength(
                        on: entity.channelType,
                        newLength: entity.stutterSegmentLength ?? 0.25
                    )
                }
            case .playSound,
                 .playTone,
                 .setLoopState,
                 .stopSound: break
            }
        case .dialDown(let entity):
            switch entity.command {
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
            case .changeDelay:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetDelay(on: entity.channelType)
                }
            case .changeReverb:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetReverb(on: entity.channelType)
                }
            case .changeFlanger:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.resetFlanger(on: entity.channelType)
                }
            case .scratch,
                 .scratchWithInertia,
                 .scratchWithBounce:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.stopScratching(on: entity.channelType)
                }
            case .stutter:
                DispatchQueue.main.async {
                    AdvancedSoundPlayer.shared.stopStutter(on: entity.channelType)
                }
            case .playSound,
                 .playTone,
                 .setLoopState,
                 .stopSound: break
            }
        case .dialUp:
            break // NOP
        case .longPressDialUp:
            break // NOP
        }
    }
}
