import StreamDeck

final class TrackIntro106TapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Track Intro 106" }
    static var actionUUID: String { "trackintro106.tap" }
    static var actionTitle: String { "Track\nIntro 106" }
    static var soundType: MessageBuilder.SoundType { .trackIntro106 }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
