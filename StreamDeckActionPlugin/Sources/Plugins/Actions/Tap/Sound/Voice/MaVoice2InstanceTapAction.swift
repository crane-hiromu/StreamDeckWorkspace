import StreamDeck

final class MaVoice2InstanceTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "MA Voice 2 Instance" }
    static var actionUUID: String { "voice.ma2.instance.tap" }
    static var actionTitle: String { "MA\nINSTANCE" }
    static var soundType: MessageBuilder.SoundType { .maVoice2Instance }
    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
    
    var channel: MessageBuilder.ChannelType { .sound }
}
