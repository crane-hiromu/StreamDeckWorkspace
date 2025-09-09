import StreamDeck

final class MaVoice7TashikaniTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 7 Tashikani" }
    static var actionUUID: String { "voice.ma7.tashikani.tap" }
    static var actionTitle: String { "MA\nTASHIKANI" }
    static var soundType: MessageBuilder.SoundType { .maVoice7Tashikani }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
    
    var channel: MessageBuilder.ChannelType { .sound }
}
