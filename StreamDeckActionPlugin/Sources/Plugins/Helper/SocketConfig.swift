import Foundation

// MARK: - SocketConfig
/// Unixソケット通信の設定を管理する構造体
/// 使用前に自分の環境に合わせて設定を変更してください
struct SocketConfig {
    
    // MARK: - Configuration
    
    /// ソケットファイルのパス
    /// サーバーアプリのBundle IDを自動取得してパスを構築
    static let socketPath: String = {
        let bundleID = findRunningServerBundleID() ?? ""
        return "\(NSHomeDirectory())/Library/Containers/\(bundleID)/Data/tmp/streamdeck.sock"
    }()
    
    /// 接続タイムアウト（秒）
    static let connectionTimeout: TimeInterval = 5.0
    
    /// 読み取りタイムアウト（秒）
    static let readTimeout: TimeInterval = 1.0
    
    /// 書き込みタイムアウト（秒）
    static let writeTimeout: TimeInterval = 1.0
    
    // MARK: - Validation
    
    /// 設定が有効かどうかを確認
    static var isValid: Bool {
        return !socketPath.isEmpty && socketPath.contains("Library/Containers/")
    }
    
    /// 設定情報をログ出力用に整形
    static var debugDescription: String {
        return """
        SocketConfig:
        - Bundle ID: \(bundleIDFromPath)
        - Socket Path: \(socketPath)
        - Connection Timeout: \(connectionTimeout)s
        - Read Timeout: \(readTimeout)s
        - Write Timeout: \(writeTimeout)s
        """
    }
    
    // MARK: - Private Helpers
        
    /// 実行中のStreamDeckSocketServerアプリのBundle IDを取得
    private static func findRunningServerBundleID() -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
               bundleID.contains("StreamDeckSocketServer") {
                return bundleID
            }
        }
        
        return nil
    }
    
    private static var bundleIDFromPath: String {
        let components = socketPath.components(separatedBy: "/")
        if let containersIndex = components.firstIndex(of: "Containers"),
           containersIndex + 1 < components.count {
            return components[containersIndex + 1]
        }
        return "Unknown"
    }
}
