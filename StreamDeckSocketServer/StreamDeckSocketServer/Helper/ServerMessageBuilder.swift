//
//  ServerMessageBuilder.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation

/**
 * サーバー側からアクションに送信するメッセージビルダークラス
 * 各メッセージタイプで使用するJSONメッセージを構築するためのヘルパークラスです。
 *
 * **NOTE: Stringで組み立てる方が、処理のオーバーヘッドが少ないため、Stringで返すようにしている。**
 */
final class ServerMessageBuilder {
    
    /**
     * JSONメッセージのキーを定義するenum
     */
    private enum MessageKeys: String {
        case type,
             data,
             channel,
             volume,
             reverb,
             delay

        var key: String { rawValue }
    }
    
    /**
     * メッセージタイプを定義するenum
     * アクション側にも同じ物がある。書き出しの都合で共有していない。
     */
    enum MessageType: String {
        case volumeChange
        case reverbChange
        case delayChange

        var key: String { rawValue }
    }

    // MARK: Message Builder

    /**
     * VolumeChange用のメッセージを構築します
     */
    static func buildVolumeChangeMessage(channel: Int? = nil, volume: Int) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(MessageType.volumeChange.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.channel.key)": \(channel ?? -1),
                "\(MessageKeys.volume.key)": \(volume)
            }
        }
        """
    }

    /**
     * ReverbChange用のメッセージを構築します
     */
    static func buildReverbChangeMessage(channel: Int, reverb: Int) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(MessageType.reverbChange.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.channel.key)": \(channel),
                "\(MessageKeys.reverb.key)": \(reverb)
            }
        }
        """
    }

    /**
     * DelayChange用のメッセージを構築します
     */
    static func buildDelayChangeMessage(channel: Int, delay: Int) -> String {
        """
        {
            "\(MessageKeys.type.key)": "\(MessageType.delayChange.key)",
            "\(MessageKeys.data.key)": {
                "\(MessageKeys.channel.key)": \(channel),
                "\(MessageKeys.delay.key)": \(delay)
            }
        }
        """
    }
}
