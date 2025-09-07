import StreamDeck

final class HaseVoice6ToiuwakdeTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 6 Toiuwakde" }
    static var actionUUID: String { "voice.hase6.toiuwakde.tap" }
    static var actionTitle: String { "HASE\nTOIUWAKDE" }
    static var soundType: MessageBuilder.SoundType { .haseVoice6Toiuwakde }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
