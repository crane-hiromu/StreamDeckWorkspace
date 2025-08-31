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

        // Unix socketクライアントを接続
        UnixSocketClient.shared.connect()
    }

    func didReceiveGlobalSettings() {
        logMessage(#function)
    }

    func willAppear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
        setTitle(to: #function)
    }

    func willDisappear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
    }

    func keyDown(context: String, payload: KeyEvent<Settings>) {
        logMessage(#function)
        // No call
    }

    // longKeyPressの後にも呼ばれるので注意
    func keyUp(device: String, payload: KeyEvent<Settings>, longPress: Bool) {
        logMessage(#function, longPress)

        setTitle(to: "タップ")

        if longPress { return }

        // Unix socketサーバーに通知を送信
        let message = """
        {
            "action": "tap",
            "device": "\(device)",
            "context": "\(context)",
            "coordinates": {
                "column": \(coordinates?.column ?? 0),
                "row": \(coordinates?.row ?? 0)
            },
            "timestamp": \(Date().timeIntervalSince1970)
        }
        """

        UnixSocketClient.shared.sendMessage(message)
    }

    func longKeyPress(device: String, payload: KeyEvent<NoSettings>) {
        logMessage(#function)

        setTitle(to: "longKeyPress")
    }

    func sendToPlugin(context: String, payload: [String: Any]) {
        logMessage(#function)
    }
}
