//
//  DrumTomTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumTomTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Drum Tom Sound"
    static var uuid: String = "drum.tom.tap"
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
        setTitle(to: "Drum\nTom")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .drumTom,
            channel: .sound,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
