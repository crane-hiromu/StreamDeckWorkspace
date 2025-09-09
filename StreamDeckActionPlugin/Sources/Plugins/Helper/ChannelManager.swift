import Foundation
import StreamDeck

/**
 * グローバルなチャンネル状態を管理するクラス
 * StreamDeck側でチャンネル状態を保持し、各アクションで使用する
 */
final class ChannelManager {
    
    // MARK: Singleton
    
    static let shared = ChannelManager()
    private init() { }
    
    // MARK: Properties
    
    private var currentChannel: MessageBuilder.ChannelType = .main
    
    // MARK: Methods
    
    /// 現在のチャンネルを取得
    func getCurrentChannel() -> MessageBuilder.ChannelType {
        currentChannel
    }
    
    /// チャンネルを切り替え
    func switchChannel() {
        currentChannel = (currentChannel == .main) ? .sub : .main
        NotificationCenter.default.post(
            name: .channelChanged,
            object: currentChannel
        )
    }
    
    /// チャンネルを設定
    func setChannel(_ channel: MessageBuilder.ChannelType) {
        currentChannel = channel
        NotificationCenter.default.post(
            name: .channelChanged,
            object: currentChannel
        )
    }
    
    /// 現在のチャンネル名を取得（表示用）
    func getCurrentChannelName() -> String {
        currentChannel == .main ? "Main" : "Sub"
    }
}

