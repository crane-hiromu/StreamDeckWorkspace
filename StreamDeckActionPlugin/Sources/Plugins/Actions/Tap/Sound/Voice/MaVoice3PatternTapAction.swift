import StreamDeck

final class MaVoice3PatternTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 3 Pattern" }
    static var actionUUID: String { "voice.ma3.pattern.tap" }
    static var actionTitle: String { "MA\nPATTERN" }
    static var soundType: MessageBuilder.SoundType { .maVoice3Pattern }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }

    var channel: MessageBuilder.ChannelType { .sound }
}
