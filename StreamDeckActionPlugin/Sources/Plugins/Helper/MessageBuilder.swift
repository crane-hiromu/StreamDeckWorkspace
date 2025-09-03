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
             coordinates,
             column,
             row

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
        case changeVolume = 1
        case changeRate = 2
        case changePitch = 3
        case changeFrequency = 4

        var value: Int { rawValue }
    }

    enum SoundType: String {
        // 効果音
        case puf
        // iOSDC素材
        case iosdc = "S_iOSDCJP"
        case beat = "S_BEAT"
        case beatL = "S_BEAT_L"

        var name: String { rawValue }
    }

    enum ChannelType: Int {
        case main, sub, two, three, four

        var id: Int { rawValue }
    }

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
     * ボリューム変更用のDialActionメッセージを構築します
     */
    static func buildVolumeDialMessage(type: MessageType,
                                       channel: ChannelType,
                                       coordinates: Coordinates?,
                                       volume: Int = 0) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(type.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.command.key)": \(MessageCommandType.changeVolume.value),
                "\(MessageKeys.channel.key)": \(channel.id),
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
}
