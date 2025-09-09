import StreamDeck

final class HaseVoice1MinnaTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "HASE Voice 1 Minna" }
    static var actionUUID: String { "voice.hase1.minna.tap" }
    static var actionTitle: String { "HASE\nMINNA" }
    static var soundType: MessageBuilder.SoundType { .haseVoice1Minna }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
    
    var channel: MessageBuilder.ChannelType { .sound }
}
