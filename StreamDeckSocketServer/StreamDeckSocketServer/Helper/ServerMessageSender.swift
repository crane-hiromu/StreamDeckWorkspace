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
    
    // MARK: Methods
    
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

    /// ボリューム変更メッセージを送信
    func sendVolumeChange(channel: Int, volume: Int) {
        sendMessage(ServerMessageBuilder.buildVolumeChangeMessage(
            channel: channel,
            volume: volume
        ))
    }
}
