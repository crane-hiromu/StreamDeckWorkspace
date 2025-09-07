import StreamDeck

final class MaVoice1SingletonTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 1 Singleton" }
    static var actionUUID: String { "voice.ma1.singleton.tap" }
    static var actionTitle: String { "MA\nSINGLETON" }
    static var soundType: MessageBuilder.SoundType { .maVoice1Singleton }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}