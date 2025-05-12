import StreamDeck

// MARK: - Plugin
@main
final class SamplePlugin: Plugin {
    static var name: String = "SamplePlugin"
    static var description: String = "A simple test plugin"
    static var author: String = "Hiromu"
    static var icon: String = "icon"
    static var version: String = "1.0"

    @ActionBuilder
    static var actions: [any Action.Type] {
        SampleAction.self
    }

    static var layouts: [Layout] {
        Layout(id: "SamplePluginLayout") {
            // The title of the layout
            Text(title: "Title")
                .textAlignment(.center)
                .frame(width: 180, height: 24)
        }
    }

    required init() { }
}
