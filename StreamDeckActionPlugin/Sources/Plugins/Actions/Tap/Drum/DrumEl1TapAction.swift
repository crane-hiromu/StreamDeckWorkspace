//
//  DrumEl1TapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumEl1TapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Drum Electronic 1 Sound"
    static var uuid: String = "drum.el1.tap"
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
        setTitle(to: "Drum\nEl 1")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .drumEl1,
            channel: .drum,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
