import StreamDeckPlugin

// MARK: - Plugin
@main
struct SamplePlugin: Plugin {
    static var name: String = "SamplePlugin"
    static var description: String = "A simple test plugin"
    static var author: String = "Hiromu"
    static var icon: String = "icon"
    static var version: String = "1.0"

    @ActionBuilder
    static var actions: [any Action.Type] {
        HelloAction.self
    }
}
