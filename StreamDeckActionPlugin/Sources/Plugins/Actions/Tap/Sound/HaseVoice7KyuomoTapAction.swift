import StreamDeck

final class HaseVoice7KyuomoTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 7 Kyuomo" }
    static var actionUUID: String { "voice.hase7.kyuomo.tap" }
    static var actionTitle: String { "HASE\nKYUOMO" }
    static var soundType: MessageBuilder.SoundType { .haseVoice7Kyuomo }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}