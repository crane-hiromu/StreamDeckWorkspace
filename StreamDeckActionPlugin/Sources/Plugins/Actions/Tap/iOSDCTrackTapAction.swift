//
//  iOSDCTrackTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import StreamDeck
import OSLog

// MARK: - Action
final class iOSDCTrackTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "iOSDC Track Sound"
    static var uuid: String = "titletrack.tap"
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
        setTitle(to: "iOSDC\nTrack")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .iosdc,
            channel: .sound,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
