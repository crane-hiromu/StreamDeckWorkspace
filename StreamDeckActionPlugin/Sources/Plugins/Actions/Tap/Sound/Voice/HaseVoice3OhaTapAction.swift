import StreamDeck

final class HaseVoice3OhaTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 3 OHA" }
    static var actionUUID: String { "voice.hase3.oha.tap" }
    static var actionTitle: String { "HASE\nOHA3" }
    static var soundType: MessageBuilder.SoundType { .haseVoice3Oha }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }

    var channel: MessageBuilder.ChannelType { .sound }
}
