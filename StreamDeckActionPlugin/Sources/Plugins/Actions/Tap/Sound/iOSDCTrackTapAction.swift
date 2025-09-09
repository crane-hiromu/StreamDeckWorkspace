//
//  iOSDCTrackTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import StreamDeck
import OSLog

// MARK: - Action
final class iOSDCTrackTapAction: SoundTapAction {
    typealias Settings = NoSettings

    // 最低限の指定だけで動く
    static var actionName: String { "iOSDC Track Sound" }
    static var actionUUID: String { "titletrack.tap" }
    static var actionTitle: String { "iOSDC\nTrack" }
    static var soundType: MessageBuilder.SoundType { .iosdc }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }

    var channel: MessageBuilder.ChannelType { .sound }
}
