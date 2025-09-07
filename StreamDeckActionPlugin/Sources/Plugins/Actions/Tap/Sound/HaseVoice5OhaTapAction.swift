import StreamDeck

final class HaseVoice5OhaTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 5 OHA" }
    static var actionUUID: String { "voice.hase5.oha.tap" }
    static var actionTitle: String { "HASE\nOHA5" }
    static var soundType: MessageBuilder.SoundType { .haseVoice5Oha }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}