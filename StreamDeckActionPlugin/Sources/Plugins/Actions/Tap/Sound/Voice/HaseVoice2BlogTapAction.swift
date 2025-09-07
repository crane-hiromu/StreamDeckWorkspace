import StreamDeck

final class HaseVoice2BlogTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 2 Blog" }
    static var actionUUID: String { "voice.hase2.blog.tap" }
    static var actionTitle: String { "HASE\nBLOG" }
    static var soundType: MessageBuilder.SoundType { .haseVoice2Blog }
    static var channelType: MessageBuilder.ChannelType { .sound }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}