//
//  SocketTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/08/31.
//

import StreamDeck
import OSLog

// MARK: - Action
class SocketTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Socket Action"
    static var uuid: String = "com.hiromu.sockettapaction"
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

        logMessage(#function, context, coordinates as Any)

        setTitle(to: "通信")
    }

    func didReceiveGlobalSettings() {
        logMessage(#function)
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        logMessage(#function)
        setTitle(to: "タップ前")

        let message = MessageBuilder.buildSocketTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: .beatL,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    // longKeyPressの後にも呼ばれるので注意
    func keyUp(device: String, payload: KeyEvent<Settings>, longPress: Bool) {
        logMessage(#function, longPress)
        setTitle(to: "タップ後")

        if longPress { return }
    }

    func longKeyPress(device: String, payload: KeyEvent<NoSettings>) {
        logMessage(#function)
        setTitle(to: "長押し")
    }

    func sendToPlugin(context: String, payload: [String: Any]) {
        logMessage(#function)
    }
}
