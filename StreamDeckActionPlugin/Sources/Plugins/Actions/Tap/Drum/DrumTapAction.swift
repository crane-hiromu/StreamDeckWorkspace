import StreamDeck
import Foundation

// MARK: - 汎用 Drum Tap Action Protocol
protocol DrumTapAction: KeyAction {
    // 各ドラムアクションで最低限指定する項目
    static var actionName: String { get }
    static var actionUUID: String { get }
    static var actionTitle: String { get }
    static var soundType: MessageBuilder.SoundType { get }
}

extension DrumTapAction {
    // KeyActionのメタ情報（デフォルト提供）
    static var name: String { actionName }
    static var uuid: String { actionUUID }
    static var icon: String { "Icons/actionIcon" }
    static var states: [PluginActionState]? { [PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)] }
    static var userTitleEnabled: Bool? { false }

    // 初期化後にタイトル設定するためのヘルパー
    func setDefaultTitle() {
        setTitle(to: Self.actionTitle)
    }

    // 押下でドラム音再生メッセージを送信（共通実装）
    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: Self.soundType,
            channel: .drum,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
