import StreamDeck
import OSLog

// MARK: - Action
struct SampleAction: Action {
    typealias Settings = NoSettings

    static var name: String = "Sample Action"
    static var uuid: String = "com.hiromu.sampleaction"
    static var icon: String = "Images/actionIcon"
    static var states: [PluginActionState]? = nil
    static var controllers: [ControllerType] = [.keypad]
    static var encoder: RotaryEncoder? = nil

    var context: String
    var coordinates: Coordinates?
    let logger = Logger(subsystem: "StreamDeckPlugin", category: "StreamDeckCommand")

    init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        logger.log("-------init-------")
    }

    func willAppear(context: String, payload: AppearEvent<NoSettings>) {
        logger.log(#function)
        setTitle(to: "Hello")
    }

    // 任意：ボタンが非表示になった時
    func willDisappear(context: String, payload: AppearEvent<NoSettings>) {
        logger.log(#function)
    }

    // 任意：ボタンが押された時
    func keyDown(context: String, payload: KeyEvent<Settings>) {
        logger.log(#function)
    }

    // 任意：ボタンを離した時
    func keyUp(context: String, payload: KeyEvent<Settings>) {
        logger.log(#function)
    }

    // 任意：定期的に呼ばれる（設定があれば）
    func sendToPlugin(context: String, payload: [String: Any]) {
        logger.log(#function)
    }
}
