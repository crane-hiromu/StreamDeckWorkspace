import StreamDeck
import OSLog

// MARK: - Action
class SampleTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Sample Action"
    static var uuid: String = "com.hiromu.sampletapaction"
    static var icon: String = "Icons/actionIcon"

    static var states: [PluginActionState]? = [
        PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)
    ]

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates

        logMessage(#function, context, coordinates as Any)

        setTitle(to: "ボタン")
    }

    func didReceiveGlobalSettings() {
        logMessage(#function)
    }

    func willAppear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
        setTitle(to: #function)
    }

    func willDisappear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        logMessage(#function)
        setTitle(to: "keyDown")
    }

    // longKeyPressの後にも呼ばれるので注意
    func keyUp(device: String, payload: KeyEvent<Settings>, longPress: Bool) {
        logMessage(#function, longPress)

        setTitle(to: "keyUp")

        if longPress { return }
    }

    func longKeyPress(device: String, payload: KeyEvent<NoSettings>) {
        logMessage(#function)

        setTitle(to: "longKeyPress")
    }

    func sendToPlugin(context: String, payload: [String: Any]) {
        logMessage(#function)
    }
}
