//
//  EffectPufTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class EffectPufTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Effect Puf Sound"
    static var uuid: String = "effect.puf.tap"
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
        setTitle(to: "Effect\nPuf")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .puf,
            channel: .sound,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
