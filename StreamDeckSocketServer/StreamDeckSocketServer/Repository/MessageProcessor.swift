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
        guard let message = JSONParser.decode(jsonString, as: MessageEntity.self) else {
            print("❌ Failed to parse JSON message: \(jsonString)")
            return
        }
        // 3. メッセージ処理
        handleMessage(message)
    }

    /// メッセージエンティティを処理する
    /// - Parameter message: 処理するメッセージエンティティ
    private func handleMessage(_ entity: MessageEntity) {
        debugPrint("📨 Processing message: \(entity)")

        switch entity.action {
        case .keyDown(let entity):
            handleKeyDown(entity)
        case .keyUp(let entity):
            handleKeyUp(entity)
        case .longKeyPress(let entity):
            handleLongKeyPress(entity)
        case .dialRotate(let entity):
            handleDialRotate(entity)
        case .dialDown(let entity):
            handleDialDown(entity)
        case .dialUp(let entity):
            handleDialUp(entity)
        case .longPressDialUp(let entity):
            handleLongPressDialUp(entity)
        }
    }

    // MARK: - Key Down Handler

    /// キーダウンイベントを処理
    private func handleKeyDown(_ entity: KeyDownEntity) {
        switch entity.command {
        case .playSound:
            executeOnMain {
                AdvancedSoundPlayer.shared.play(
                    named: entity.sound ?? "",
                    on: entity.channelType
                )
            }
        case .playTone:
            executeOnMain {
                AdvancedSoundPlayer.shared.playTone(
                    entity.note ?? "C",
                    on: entity.channelType
                )
            }
        case .setLoopState:
            executeOnMain {
                AdvancedSoundPlayer.shared.toggleLoop(on: entity.channelType)
            }
        case .stopSound:
            executeOnMain {
                AdvancedSoundPlayer.shared.stop(entity.channelType)
            }
        case .stopAllSound:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetAll()
            }
        case .stutter:
            executeOnMain {
                AdvancedSoundPlayer.shared.startStutter(
                    on: entity.channelType,
                    segmentLength: entity.stutterSegmentLength ?? 0.25
                )
            }
        case .changeSystemVolume,
             .changeChannelVolume,
             .changeRate,
             .changePitch,
             .changeFrequency,
             .changeDelay,
             .changeReverb,
             .changeFlanger,
             .scratch,
             .scratchWithInertia,
             .scratchWithBounce:
            break
        }
    }

    // MARK: - Key Up Handler

    /// キーアップイベントを処理
    private func handleKeyUp(_ entity: KeyUpEntity) {
        // NOP
    }

    // MARK: - Long Key Press Handler

    /// ロングキープレスイベントを処理
    private func handleLongKeyPress(_ entity: LongKeyPressEntity) {
        // NOP
    }

    // MARK: - Dial Rotate Handler

    /// ダイヤル回転イベントを処理
    private func handleDialRotate(_ entity: DialRotateEntity) {
        switch entity.command {
        case .changeSystemVolume:
            executeOnMain {
                SystemVolumeManager.shared.adjustVolume(
                    by: (Float(entity.volume ?? 0) / 20.0)
                )
            }
        case .changeChannelVolume:
            executeOnMain {
                AdvancedSoundPlayer.shared.adjustChannelVolume(
                    by: (Float(entity.volume ?? 0) / 20.0),
                    on: entity.channelType
                )
            }
        case .changeRate:
            executeOnMain {
                AdvancedSoundPlayer.shared.changeRate(
                    on: entity.channelType,
                    step: entity.rate ?? 0
                )
            }
        case .changePitch:
            executeOnMain {
                AdvancedSoundPlayer.shared.changePitch(
                    on: entity.channelType,
                    step: entity.pitch ?? 0
                )
            }
        case .changeFrequency:
            executeOnMain {
                AdvancedSoundPlayer.shared.setIsolatorBalance(
                    on: entity.channelType,
                    value: Float(entity.frequency ?? 0)
                )
            }
        case .changeDelay:
            executeOnMain {
                AdvancedSoundPlayer.shared.changeDelayMix(
                    on: entity.channelType,
                    step: entity.delay ?? 0
                )
            }
        case .changeReverb:
            executeOnMain {
                AdvancedSoundPlayer.shared.changeReverbWetDryMix(
                    on: entity.channelType,
                    step: entity.reverb ?? 0
                )
            }
        case .changeFlanger:
            executeOnMain {
                AdvancedSoundPlayer.shared.changeFlangerWetDryMix(
                    on: entity.channelType,
                    step: entity.flanger ?? 0
                )
            }
        case .scratch:
            executeOnMain {
                AdvancedSoundPlayer.shared.startScratch(
                    on: entity.channelType,
                    value: entity.scratch ?? 0
                )
            }
        case .scratchWithInertia:
            executeOnMain {
                AdvancedSoundPlayer.shared.scratchWithInertia(
                    on: entity.channelType,
                    value: entity.scratch ?? 0,
                    sensitivity: entity.scratchSensitivity ?? 1.0
                )
            }
        case .scratchWithBounce:
            executeOnMain {
                AdvancedSoundPlayer.shared.scratchWithBounce(
                    on: entity.channelType,
                    value: entity.scratch ?? 0
                )
            }
        case .stutter:
            executeOnMain {
                AdvancedSoundPlayer.shared.updateStutterSegmentLength(
                    on: entity.channelType,
                    newLength: entity.stutterSegmentLength ?? 0.25
                )
            }
        case .playSound,
             .playTone,
             .setLoopState,
             .stopSound,
             .stopAllSound:
            break
        }
    }

    // MARK: - Dial Down Handler

    /// ダイヤル押下イベントを処理
    private func handleDialDown(_ entity: DialDownEntity) {
        switch entity.command {
        case .changeSystemVolume:
            executeOnMain {
                SystemVolumeManager.shared.toggleMute()
            }
        case .changeChannelVolume:
            executeOnMain {
                AdvancedSoundPlayer.shared.toggleChannelMute(on: entity.channelType)
            }
        case .changeRate:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetRate(on: entity.channelType)
            }
        case .changePitch:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetPitch(on: entity.channelType)
            }
        case .changeFrequency:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetIsolator(on: entity.channelType)
            }
        case .changeDelay:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetDelay(on: entity.channelType)
            }
        case .changeReverb:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetReverb(on: entity.channelType)
            }
        case .changeFlanger:
            executeOnMain {
                AdvancedSoundPlayer.shared.resetFlanger(on: entity.channelType)
            }
        case .scratch,
             .scratchWithInertia,
             .scratchWithBounce:
            executeOnMain {
                AdvancedSoundPlayer.shared.stopScratching(on: entity.channelType)
            }
        case .stutter:
            executeOnMain {
                AdvancedSoundPlayer.shared.stopStutter(on: entity.channelType)
            }
        case .playSound,
             .playTone,
             .setLoopState,
             .stopSound,
             .stopAllSound:
            break
        }
    }

    // MARK: - Dial Up Handler

    /// ダイヤルアップイベントを処理
    private func handleDialUp(_ entity: DialUpEntity) {
        // NOP
    }

    // MARK: - Long Press Dial Up Handler

    /// ロングプレスダイヤルアップイベントを処理
    private func handleLongPressDialUp(_ entity: LongPressDialUpEntity) {
        // NOP
    }

    // MARK: - Helper Methods

    /// メインスレッドで実行するヘルパーメソッド
    private func executeOnMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }
}
