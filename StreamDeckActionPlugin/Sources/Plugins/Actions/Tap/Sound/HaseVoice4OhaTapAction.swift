import StreamDeck

final class HaseVoice4OhaTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 4 OHA" }
    static var actionUUID: String { "voice.hase4.oha.tap" }
    static var actionTitle: String { "HASE\nOHA4" }
    static var soundType: MessageBuilder.SoundType { .haseVoice4Oha }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}