//
//  DrumCymbalTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumCymbalTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Drum Cymbal Sound"
    static var uuid: String = "drum.cymbal.tap"
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
        setTitle(to: "Drum\nCymbal")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .drumCymbal,
            channel: .drum,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
