import Foundation
import StreamDeck
import OSLog

// MARK: - UnixSocketClient
final class UnixSocketClient {

    // MARK: Singleton

    static let shared = UnixSocketClient()
    private init() { }

    // MARK: Properties

    private var socket: Int32 = -1
    // サーバー側の NSHomeDirectory() で生成される実際のパスをセット
    private let socketPath = "\(NSHomeDirectory())/Library/Containers/h.crane.t.StreamDeckSocketServer/Data/tmp/streamdeck.sock"
    private let log = Logger(subsystem: "StreamDeckPlugin", category: "Action")

    // MARK: Methods
    
    func connect() {
        logMessage(#function)

        guard socket == -1 else {
            logMessage(#function + " Unix socket already connected")
            return
        }
        
        // ソケットを作成
        socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard socket != -1 else {
            logMessage(#function + " Failed to create socket")
            return
        }
        
        // サーバーアドレスを設定
        // 基本的にはPOSIX API (C の低レベルソケットAPI)をSwiftから呼んでおり、 C の定義を Swift に自動ブリッジしている
        var serverAddr = sockaddr_un()
        serverAddr.sun_family = sa_family_t(AF_UNIX)
        strncpy(&serverAddr.sun_path, socketPath, Int(socklen_t(socketPath.count)))
        
        // 接続
        let result = Darwin.connect(socket, sockaddr_cast(&serverAddr), socklen_t(MemoryLayout<sockaddr_un>.size))
        if result == 0 {
            logMessage(#function + " Unix socket connected to \(self.socketPath)")
        } else {
            logMessage(#function + " Failed to connect Unix socket: \(errno)")
            close(socket)
            socket = -1
        }
    }
    
    func sendMessage(_ message: String) {
        logMessage(#function)

        guard socket != -1 else {
            logMessage(#function + " Unix socket not connected, attempting to reconnect...")
            connect()
            return
        }
        
        // バイト列に変換 
        // ex hello -> [72, 101, 108, 108, 111]
        guard let data = message.data(using: .utf8) else {
            logMessage(#function + " Failed to convert message to data")
            return
        }
        let result = data.withUnsafeBytes { buffer in
            Darwin.write(socket, buffer.baseAddress, buffer.count)
        }
        
        if result > 0 {
            logMessage(#function + " Message sent successfully: \(message)")
        } else {
            logMessage(#function + " Failed to send message: \(errno)")
        }
    }
    
    /// サーバーからのメッセージを受信する
    /// - Parameter completion: 受信したメッセージを処理するクロージャ
    func startReceivingMessages(completion: @escaping (String) -> Void) {
        guard socket != -1 else {
            logMessage("startReceivingMessages: Unix socket not connected")
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            while self.socket != -1 {
                let bytesRead = Darwin.read(self.socket, &buffer, bufferSize)
                
                if bytesRead > 0 {
                    if let message = String(data: Data(buffer.prefix(bytesRead)), encoding: .utf8) {
                        DispatchQueue.main.async {
                            completion(message)
                        }
                    }
                } else if bytesRead == 0 {
                    self.logMessage("Server disconnected")
                    break
                } else {
                    self.logMessage("Failed to read from socket: \(errno)")
                    break
                }
            }
        }
    }
    
    func disconnect() {
        logMessage(#function)

        if socket != -1 {
            close(socket)
            socket = -1
            logMessage(#function + " Unix socket disconnected")
        }
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - Helper
private extension UnixSocketClient {

    func sockaddr_cast(_ ptr: UnsafePointer<sockaddr_un>) -> UnsafePointer<sockaddr> {
        UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
    }

    func logMessage(_ message: String) {
        log.log("\(message, privacy: .public)")

        Task {
            await PluginCommunication.shared.sendEvent(
                .logMessage,
                context: nil,
                payload: ["message": message]
            )
        }
    }
}
