//
//  StopTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class StopTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Stop Tap"
    static var uuid: String = "stoptap.tap"
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
        setTitle(to: "Stop")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildStopTapMessage(
            type: .keyDown,
            command: .stopSound,
            channel: .main,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}

