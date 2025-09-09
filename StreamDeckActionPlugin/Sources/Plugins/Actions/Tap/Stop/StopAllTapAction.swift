import Foundation
import StreamDeck

// MARK: - Action (All Stop)
final class StopAllTapAction: StopTapActionProtocol {
    typealias Settings = NoSettings

    static var name: String = "Stop All"
    static var uuid: String = "stopall.tap"
    static var icon: String = "Icons/actionIcon"

    static var states: [PluginActionState]? = [
        PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)
    ]

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: Coordinates?

    // 全停止のため channel は未指定
    var channel: MessageBuilder.ChannelType? { nil }

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }

    func updateTitle() { setTitle(to: "Stop\nAll") }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildStopTapMessage(
            type: .keyDown,
            command: .stopAllSound,
            channel: channel,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}


