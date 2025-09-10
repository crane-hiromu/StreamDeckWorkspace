import StreamDeck
import Foundation

// MARK: - Channel Switch Action
final class ChannelSwitchTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Channel Switch"
    static var uuid: String = "channel.switch.tap"
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
        updateTitle()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(channelChanged),
            name: .channelChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        ChannelManager.shared.switchChannel()

        let message = MessageBuilder.buildChannelSwitchTapMessage(
            type: .keyDown,
            command: .switchChannel,
            channel: ChannelManager.shared.getCurrentChannel(),
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
    
    @objc private func channelChanged() {
        updateTitle()
    }
    
    private func updateTitle() {
        let channelName = ChannelManager.shared.getCurrentChannelName()
        setTitle(to: channelName)
    }
}
