import Foundation
import StreamDeck
import OSLog

/**
 * StreamDeckアクション用のメッセージビルダークラス
 * 各アクションで使用するJSONメッセージを構築するためのヘルパークラスです。
 *
 * **NOTE: Stringで組み立てる方が、処理のオーバーヘッドが少ないため、Stringで返すようにしている。**
 */
final class MessageBuilder {
    
    /**
     * JSONメッセージのキーを定義するenum
     */
    private enum MessageKeys: String {
        case type,
             data,
             sound,
             command,
             channel,
             volume,
             pitch,
             rate,
             frequency,
             delay,
             reverb,
             flanger,
             scratch,
             coordinates,
             column,
             row,
             note,
             stutterSegmentLength

        var key: String { rawValue }
    }
    
    /**
     * メッセージタイプを定義するenum
     * サーバー側にも同じ物がある。書き出しの都合で共有していない。
     */
    enum MessageType: String {
        case keyDown, keyUp, longKeyPress
        case dialRotate, dialDown, dialUp, longPressDialUp

        var key: String { rawValue }
    }

    /**
     * コマンドタイプを定義するenum
     * サーバー側にも同じ物がある。書き出しの都合で共有していない。
     */
    enum MessageCommandType: Int {
        case playSound = 0
        case changeSystemVolume
        case changeChannelVolume
        case changeRate
        case changePitch
        case changeFrequency
        case setLoopState
        case stopSound
        case changeDelay
        case changeReverb
        case changeFlanger
        case scratch
        case scratchWithInertia
        case scratchWithBounce
        case playTone
        case stutter

        var value: Int { rawValue }
    }

    enum SoundType: String {
        // 効果音
        case puf
        
        // ドラム音
        case drumBass = "DRUM_D_BASS"
        case drumCymbal = "DRUM_D_CYMBAL"
        case drumHat = "DRUM_D_HAT"
        case drumSnareS = "DRUM_D_SNARE_S"
        case drumSnareW = "DRUM_D_SNARE_W"
        case drumTom = "DRUM_D_TOM"
        case drumEl1 = "DRUM_EL_1"
        case drumEl2 = "DRUM_EL_2"
        case drumEl3 = "DRUM_EL_3"
        
        // iOSDC素材
        case iosdc = "S_iOSDCJP"
        case beat = "S_BEAT"

        var name: String { rawValue }
    }

    enum ChannelType: Int {
        // トラック用のチャンネル
        case main, sub
        // 効果音用のチャンネル
        case sound
        // ドラム専用チャンネル
        case drum
        // 鍵盤専用チャンネル
        case keyboard

        var id: Int { rawValue }
    }

    // MARK: Tap Action

    /**
     * TapAction用のメッセージを構築します
     */
    static func buildTapMessage(type: MessageType,
                                command: MessageCommandType,
                                sound: SoundType,
                                channel: ChannelType,
                                coordinates: Coordinates?) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(command.value),
                "\(MessageKeys.sound.key)": "\(sound.name)",
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                }
            }
        }
        """
    }

    /**
     * LoopAction用のメッセージを構築します
     */
    static func buildLoopTapMessage(type: MessageType,
                                    command: MessageCommandType,
                                    channel: ChannelType,
                                    coordinates: Coordinates?) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(command.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                }
            }
        }
        """
    }

    /**
     * StopAction用のメッセージを構築します（sound不要）
     */
    static func buildStopTapMessage(type: MessageType,
                                    command: MessageCommandType,
                                    channel: ChannelType,
                                    coordinates: Coordinates?) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(command.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                }
            }
        }
        """
    }

    // MARK: Dial Action

    /**
     * ボリューム変更用のDialActionメッセージを構築します
     */
    static func buildVolumeDialMessage(type: MessageType,
                                       channel: ChannelType? = nil,
                                       coordinates: Coordinates?,
                                       volume: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \({
                    channel == nil
                        ? MessageCommandType.changeSystemVolume.value
                        : MessageCommandType.changeChannelVolume.value
                }()),
                "\(MessageKeys.channel.key)": \(channel?.id ?? -1),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.volume.key)": \(volume)
            }
        }
        """
    }
    
    /**
     * レート変更用のDialActionメッセージを構築します
     */
    static func buildRateDialMessage(type: MessageType,
                                     channel: ChannelType,
                                     coordinates: Coordinates?,
                                     rate: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeRate.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.rate.key)": \(rate)
            }
        }
        """
    }
    
    /**
     * ピッチ変更用のDialActionメッセージを構築します
     */
    static func buildPitchDialMessage(type: MessageType,
                                      channel: ChannelType,
                                      coordinates: Coordinates?,
                                      pitch: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changePitch.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.pitch.key)": \(pitch)
            }
        }
        """
    }
    
    /**
     * 周波数変更用のDialActionメッセージを構築します
     */
    static func buildFrequencyDialMessage(type: MessageType,
                                          channel: ChannelType,
                                          coordinates: Coordinates?,
                                          frequency: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeFrequency.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.frequency.key)": \(frequency)
            }
        }
        """
    }

    /**
     * ディレイ変更（マクロ一括）用のDialActionメッセージを構築します
     * - parameter delay: 回転ステップ値（サーバ側で正規化して k∈[-1,1] に変換）
     */
    static func buildDelayDialMessage(type: MessageType,
                                      channel: ChannelType,
                                      coordinates: Coordinates?,
                                      delay: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeDelay.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.delay.key)": \(delay)
            }
        }
        """
    }

    /**
     * リバーブ変更（マクロ一括）用のDialActionメッセージを構築します
     * - parameter reverb: 回転ステップ値（サーバ側で正規化して k∈[-1,1] に変換）
     */
    static func buildReverbDialMessage(type: MessageType,
                                       channel: ChannelType,
                                       coordinates: Coordinates?,
                                       reverb: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeReverb.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.reverb.key)": \(reverb)
            }
        }
        """
    }

    /**
     * フランジャー変更（マクロ一括）用のDialActionメッセージを構築します
     * - parameter flanger: 回転ステップ値（サーバ側で正規化して k∈[-1,1] に変換）
     */
    static func buildFlangerDialMessage(type: MessageType,
                                        channel: ChannelType,
                                        coordinates: Coordinates?,
                                        flanger: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeFlanger.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.flanger.key)": \(flanger)
            }
        }
        """
    }

    /**
     * スクラッチ用ダイヤルメッセージを構築
     */
    static func buildScratchDialMessage(type: MessageType,
                                        channel: ChannelType,
                                        coordinates: Coordinates?,
                                        scratch: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.scratchWithInertia.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.scratch.key)": \(scratch)
            }
        }
        """
    }
    
    /**
     * トーン再生用のTapActionメッセージを構築します
     */
    static func buildToneTapMessage(type: MessageType,
                                    command: MessageCommandType,
                                    channel: ChannelType,
                                    coordinates: Coordinates?,
                                    note: String) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(command.value),
                "\(MessageKeys.note.key)": "\(note)",
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                }
            }
        }
        """
    }
    
    /**
     * ストッター用のTapActionメッセージを構築します
     */
    static func buildStutterTapMessage(type: MessageType,
                                       command: MessageCommandType,
                                       channel: ChannelType,
                                       segmentLength: Double,
                                       coordinates: Coordinates?) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(command.value),
                "\(MessageKeys.stutterSegmentLength.key)": \(segmentLength),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                }
            }
        }
        """
    }
    
    /**
     * ストッター用のDialActionメッセージを構築します
     */
    static func buildStutterDialMessage(type: MessageType,
                                        channel: ChannelType,
                                        coordinates: Coordinates?,
                                        segmentLength: Double = 0.25) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.stutter.value),
                "\(MessageKeys.channel.key)": \(channel.id),
                "\(MessageKeys.coordinates.key)": {
                    "\(MessageKeys.column.key)": \(coordinates?.column ?? -1),
                    "\(MessageKeys.row.key)": \(coordinates?.row ?? -1)
                },
                "\(MessageKeys.stutterSegmentLength.key)": \(segmentLength)
            }
        }
        """
    }
}
