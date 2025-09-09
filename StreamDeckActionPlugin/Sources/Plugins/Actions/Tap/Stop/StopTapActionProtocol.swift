import Foundation
import StreamDeck

/// 停止系TapActionの共通プロトコル
protocol StopTapActionProtocol: KeyAction where Settings == NoSettings {
    /// 停止対象チャンネル（nilなら全停止）
    var channel: MessageBuilder.ChannelType? { get }
    /// ボタンタイトルを更新
    func updateTitle()
}

extension StopTapActionProtocol {
    // 既定のメタ情報
    static var icon: String { "Icons/actionIcon" }
    static var states: [PluginActionState]? {
        [PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)]
    }
    static var userTitleEnabled: Bool? { false }

    // デフォルトのチャンネルは現在選択中
    var channel: MessageBuilder.ChannelType? { ChannelManager.shared.getCurrentChannel() }

    // 送信処理（共通）
    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let command: MessageBuilder.MessageCommandType = (channel == nil) ? .stopAllSound : .stopSound
        let message = MessageBuilder.buildStopTapMessage(
            type: .keyDown,
            command: command,
            channel: channel,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}


