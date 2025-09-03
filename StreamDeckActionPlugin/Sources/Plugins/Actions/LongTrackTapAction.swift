//
//  LongTrackTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/08/31.
//

import StreamDeck
import OSLog

// MARK: - Action
final class LongTrackTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Long Track Sound"
    static var uuid: String = "longtrack.tap"
    static var icon: String = "Icons/actionIcon"

    static var states: [PluginActionState]? = [
        PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)
    ]

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setTitle(to: "Long\nTrack")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .beatL,
            channel: .main,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
