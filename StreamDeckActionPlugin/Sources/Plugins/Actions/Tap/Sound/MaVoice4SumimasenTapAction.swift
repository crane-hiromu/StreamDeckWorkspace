import StreamDeck

final class MaVoice4SumimasenTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 4 Sumimasen" }
    static var actionUUID: String { "voice.ma4.sumimasen.tap" }
    static var actionTitle: String { "MA\nSUMIMASEN" }
    static var soundType: MessageBuilder.SoundType { .maVoice4Sumimasen }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}