//
//  LoopTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import StreamDeck
import OSLog

// MARK: - Action
final class LoopTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Loop Tap"
    static var uuid: String = "looptap.tap"
    static var icon: String = "Icons/actionIcon"

    static var states: [PluginActionState]? = [
        PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)
    ]

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: Coordinates?

    private var loop: Bool = false

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildLoopTapMessage(
            type: .keyDown,
            command: .setLoopState,
            channel: .main,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)

        loop.toggle()
        updateTitle()
    }

    private func updateTitle() {
        setTitle(to: "Loop\n\(loop ? "ON" : "OFF")")
    }
}

