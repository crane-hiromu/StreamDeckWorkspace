import StreamDeck

final class MaVoice6OioiTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 6 Oioi" }
    static var actionUUID: String { "voice.ma6.oioi.tap" }
    static var actionTitle: String { "MA\nOIOI" }
    static var soundType: MessageBuilder.SoundType { .maVoice6Oioi }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}