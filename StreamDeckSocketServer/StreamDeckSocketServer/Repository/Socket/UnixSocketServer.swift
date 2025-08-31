//
//  UnixSocketServer.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - Socket Server
final class UnixSocketServer {

    // MARK: Property

    private let socketPath = NSHomeDirectory() + "/tmp/streamdeck.sock"
    private var serverSocket = SocketDescriptor()
    private var clientSocket = SocketDescriptor()

    // MARK: Method

    /// Unixソケットサーバーを開始する
    /// 
    /// 以下の処理を順次実行します：
    /// 1. 既存のソケットファイルを削除
    /// 2. Unixソケットを作成
    /// 3. ソケットオプションを設定
    /// 4. サーバーをバインド
    /// 5. リッスンを開始
    /// 6. 接続受け入れを開始
    func startServer() {
        cleanupExistingSocket()

        guard createUnixSocket() else {
            print("❌ Failed to create Unix socket")
            return
        }

        configureSocketOptions()

        guard bindServerSocket() else {
            print("❌ Failed to bind Unix socket: \(errno)")
            close(serverSocket.value)
            return
        }

        guard startListening() else {
            print("❌ Failed to listen on Unix socket: \(errno)")
            close(serverSocket.value)
            return
        }

        print("🟢 Unix socket server started on \(socketPath)")

        // 接続を受け付けるスレッド
        DispatchQueue.global(qos: .background).async {
            self.acceptConnections()
        }
    }

    /// クライアント接続を継続的に受け入れる
    /// 
    /// 無限ループでクライアント接続を待ち受け、接続が確立されると
    /// 別スレッドでクライアントとの通信を開始します。
    func acceptConnections() {
        while true {
            guard acceptClientConnection() else {
                print("❌ Failed to accept connection: \(errno)")
                continue
            }
            print("🟢 Unix socket client connected")

            // クライアントからのデータを受信
            DispatchQueue.global(qos: .background).async {
                self.handleClient()
            }
        }
    }

    /// クライアントとの通信を処理する
    /// 
    /// クライアントから送信されたデータを継続的に読み取り、
    /// メッセージを受信するとサウンドを再生します。
    /// 接続が閉じられるかエラーが発生するまで継続します。
    func handleClient() {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while true {
            let result = readDataFromClient(buffer: &buffer, bufferSize: bufferSize)

            switch result {
            case .success(let count):
                processReceivedMessage(buffer: buffer, bytesRead: count)
            case .connectionClosed:
                print("🔌 Unix socket client disconnected")
                break
            case .error:
                print("❌ Unix socket read error: \(errno)")
                break
            }
        }

        close(clientSocket.value)
    }

    /// Unixソケットサーバーを停止する
    /// 
    /// サーバーソケットとクライアントソケットを閉じ、
    /// 既存のソケットファイルを削除します。
    func stopServer() {
        guard serverSocket.isValid else { return }

        close(serverSocket.value)
        close(clientSocket.value)
        serverSocket.reset()
        cleanupExistingSocket()

        print("🔴 Unix socket server stopped")
    }
}

// MARK: - Private Methods
private extension UnixSocketServer {

    // MARK: Server Socket

    /// Unixソケットを作成する
    /// - Returns: 作成が成功したかどうか
    func createUnixSocket() -> Bool {
        serverSocket.value = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        return serverSocket.isValid
    }

    /// 既存のソケットファイルを削除する
    func cleanupExistingSocket() {
        unlink(socketPath)
    }

    /// ソケットオプションを設定する
    func configureSocketOptions() {
        var optval: Int32 = 1

        setsockopt(serverSocket.value,
                   SOL_SOCKET,
                   SO_REUSEADDR,
                   &optval,
                   SocketHelper.int32_size())
    }

    /// サーバーアドレスを設定する
    /// - Returns: 設定されたsockaddr_un構造体
    func configureServerAddress() -> sockaddr_un {
        var serverAddr = sockaddr_un()
        serverAddr.sun_family = sa_family_t(AF_UNIX)
        strncpy(&serverAddr.sun_path, socketPath, Int(socklen_t(socketPath.count)))
        return serverAddr
    }
    
    /// サーバーソケットをバインドする
    /// - Returns: バインドが成功したかどうか
    func bindServerSocket() -> Bool {
        var serverAddr = configureServerAddress()
        let bindResult = Darwin.bind(serverSocket.value,
                                     SocketHelper.sockaddr_cast(&serverAddr),
                                     SocketHelper.sockaddr_un_size())

        return DarwinResult(rawValue: bindResult) == .success
    }
    
    /// リッスンを開始する
    /// - Returns: リッスン開始が成功したかどうか
    func startListening() -> Bool {
        let listenResult = Darwin.listen(serverSocket.value, 5)
        return DarwinResult(rawValue: listenResult) == .success
    }

    // MARK: Client Socket
    
    /// クライアント接続を受け入れる
    /// - Returns: 接続受け入れが成功したかどうか
    func acceptClientConnection() -> Bool {
        var clientAddr = sockaddr_un()
        var addrLen = SocketHelper.sockaddr_un_size()

        clientSocket.value = Darwin.accept(serverSocket.value,
                                           SocketHelper.sockaddr_cast_mutable(&clientAddr),
                                           &addrLen)
        return clientSocket.isValid
    }
    
    /// クライアントからデータを読み取る
    /// - Parameters:
    ///   - buffer: 読み取り用バッファ
    ///   - bufferSize: バッファサイズ
    /// - Returns: 読み取り結果
    func readDataFromClient(buffer: inout [UInt8], bufferSize: Int) -> ReadResult {
        let bytesRead = Darwin.read(clientSocket.value, &buffer, bufferSize)
        return SocketHelper.readResult(bytesRead)
    }
    
    /// 受信したメッセージを処理する
    /// - Parameters:
    ///   - buffer: 受信データのバッファ
    ///   - bytesRead: 読み取ったバイト数
    func processReceivedMessage(buffer: [UInt8], bytesRead: Int) {
        // 1. Buffer → String
        guard let jsonString = SocketHelper.parseUTF8String(from: buffer, bytesRead: bytesRead) else {
            print("❌ Failed to parse UTF-8 string")
            return
        }
        // 2. String → JSON → Entity
        guard let message = parseMessageFromJSON(jsonString) else {
            print("❌ Failed to parse JSON message: \(jsonString)")
            return
        }
        // 3. メッセージ処理
        handleParsedMessage(message)
    }
    
    /// JSON文字列からメッセージエンティティを解析する
    /// - Parameter jsonString: JSON形式の文字列
    /// - Returns: 解析されたメッセージ、失敗時はnil
    private func parseMessageFromJSON(_ jsonString: String) -> MessageEntity? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let message = try JSONDecoder().decode(MessageEntity.self, from: data)
            return message
        } catch {
            print("❌ JSON decode error: \(error)")
            return nil
        }
    }
    
    /// 解析されたメッセージを処理する
    /// - Parameter message: 解析されたメッセージエンティティ
    private func handleParsedMessage(_ message: MessageEntity) {
        print("📨 Received parsed message: \(message)")

        // todo 
        // entityからactionを取得し、そのactionに応じて処理を行う
        
        DispatchQueue.main.async {
            SoundPlayer.shared.playSound(named: "puf")
        }
    }
}
