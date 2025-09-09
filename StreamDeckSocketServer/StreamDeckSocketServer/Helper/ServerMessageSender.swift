import Foundation

/**
 * サーバー側からアクションにメッセージを送信するヘルパークラス
 */
final class ServerMessageSender {

    // MARK: Singleton
    
    static let shared = ServerMessageSender()
    private init() { }


    // MARK: Properties
    
    private var unixSocketServer: UnixSocketServer?
    
    // MARK: Common
    
    /// UnixSocketServerの参照を設定する
    /// - Parameter server: UnixSocketServerのインスタンス
    func setUnixSocketServer(_ server: UnixSocketServer) {
        self.unixSocketServer = server
    }

    /// メッセージを送信する
    func sendMessage(_ message: String) {
        guard let server = unixSocketServer else {
            print("❌ UnixSocketServer not set")
            return
        }
        server.sendMessageToClient(message)
    }

    // MARK: Volume

    /// システムボリューム変更メッセージを送信
    func sendSystemVolumeChange(volume: Int) {
        sendMessage(ServerMessageBuilder.buildVolumeChangeMessage(
            volume: volume
        ))
    }

    /// チャンネルボリューム変更メッセージを送信
    func sendChannelVolumeChange(channel: Int, volume: Int) {
        sendMessage(ServerMessageBuilder.buildVolumeChangeMessage(
            channel: channel,
            volume: volume
        ))
    }

    /// 全チャンネルのボリュームを初期値(100)で送信
    func sendChannelVolumeResetAllChannels() {
        for channel in AdvancedSoundPlayer.Channel.allCases {
            sendChannelVolumeChange(channel: channel.rawValue, volume: 100)
        }
    }

    // MARK: Reverb

    /// リバーブ変更メッセージを送信
    func sendReverbChange(channel: Int, reverb: Int) {
        sendMessage(ServerMessageBuilder.buildReverbChangeMessage(
            channel: channel,
            reverb: reverb
        ))
    }

    /// 全チャンネルのリバーブ値リセットを送信
    func sendReverbResetAllChannels() {
        for channel in AdvancedSoundPlayer.Channel.allCases {
            sendReverbChange(channel: channel.rawValue, reverb: 0)
        }
    }
}
