import StreamDeck

final class MaVoice5TwoTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 5 Two" }
    static var actionUUID: String { "voice.ma5.two.tap" }
    static var actionTitle: String { "MA\nTWO" }
    static var soundType: MessageBuilder.SoundType { .maVoice5Two }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
    
    var channel: MessageBuilder.ChannelType { .sound }
}
