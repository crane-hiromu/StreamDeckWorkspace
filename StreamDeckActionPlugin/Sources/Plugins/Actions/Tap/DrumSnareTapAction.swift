//
//  DrumSnareTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumSnareTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Drum Snare Sound"
    static var uuid: String = "drum.snare.tap"
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
        setTitle(to: "Drum\nSnare")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .drumSnareS,
            channel: .sound,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
