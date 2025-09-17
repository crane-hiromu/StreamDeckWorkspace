import StreamDeck
import Foundation

// MARK: - 汎用 Sound Tap Action Protocol
protocol SoundTapAction: KeyAction {
    // 各アクションで最低限指定する項目
    static var actionName: String { get }
    static var actionUUID: String { get }
    static var actionTitle: String { get }
    static var soundType: MessageBuilder.SoundType { get }
    
    /// 使用するチャンネルを取得
    /// デフォルトはChannelManager.shared.getCurrentChannel()
    var channel: MessageBuilder.ChannelType { get }
}

extension SoundTapAction {
    // KeyActionのメタ情報（デフォルト提供）
    static var name: String { actionName }
    static var uuid: String { actionUUID }
    static var icon: String { "Icons/actionIcon" }
    static var states: [PluginActionState]? { 
        [PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)] 
    }
    static var userTitleEnabled: Bool? { false }

    // デフォルトのチャンネル設定
    var channel: MessageBuilder.ChannelType {
        ChannelManager.shared.getCurrentChannel()
    }

    // 初期化後にタイトル設定するためのヘルパー
    func setDefaultTitle() {
        setTitle(to: Self.actionTitle)
    }

    // 押下でサウンド再生メッセージを送信（共通実装）
    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: Self.soundType,
            channel: self.channel,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}

// MARK: - Rhythm S_1_SF
final class RhythmS1SFTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Rhythm S_1_SF Sound" }
    static var actionUUID: String { "rhythm.s1sf.tap" }
    static var actionTitle: String { "Rhythm\nS1_SF" }
    static var soundType: MessageBuilder.SoundType { .rhythmS1SF }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}

// MARK: - Rhythm S_2_MIS
final class RhythmS2MISTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Rhythm S_2_MIS Sound" }
    static var actionUUID: String { "rhythm.s2mis.tap" }
    static var actionTitle: String { "Rhythm\nS2_MIS" }
    static var soundType: MessageBuilder.SoundType { .rhythmS2MIS }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
