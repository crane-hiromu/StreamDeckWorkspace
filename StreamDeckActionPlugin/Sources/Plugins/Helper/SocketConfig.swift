import Foundation

// MARK: - SocketConfig
/// Unixソケット通信の設定を管理する構造体
/// 使用前に自分の環境に合わせて設定を変更してください
struct SocketConfig {
    
    // MARK: - Configuration
    
    /// ソケットファイルのパス
    /// ⚠️ 重要: 自分のBundle IDに合わせて変更してください
    /// Bundle IDは StreamDeckSocketServer.xcodeproj のプロジェクト設定で確認可能
    static let socketPath: String = {
        // 自分のBundle IDに変更してください
        let bundleID = "h.crane.t.StreamDeckSocketServer" // ← ここを変更
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
    
    private static var bundleIDFromPath: String {
        let components = socketPath.components(separatedBy: "/")
        if let containersIndex = components.firstIndex(of: "Containers"),
           containersIndex + 1 < components.count {
            return components[containersIndex + 1]
        }
        return "Unknown"
    }
}
