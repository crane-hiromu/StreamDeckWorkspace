import StreamDeck

final class WaitingBass104TapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Waiting Bass 104" }
    static var actionUUID: String { "waitingbass104.tap" }
    static var actionTitle: String { "Waiting\nBass 104" }
    static var soundType: MessageBuilder.SoundType { .waitingBass104 }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
