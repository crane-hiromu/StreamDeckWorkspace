import Cocoa
import SwiftUI

// MARK: - AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Delegate Method

    func applicationDidFinishLaunching(_ notification: Notification) {
        UnixSocketServer.shared.startServer()
        // オーディオエンジンを事前起動（初回再生の遅延を回避）
        AdvancedSoundPlayer.shared.prewarmAudioEngine()
        ServerMessageSender.shared.setUnixSocketServer(UnixSocketServer.shared)
        
        // ウィンドウの最小サイズを設定
        setupWindowConstraints()
    }

    func applicationWillTerminate(_ notification: Notification) {
        UnixSocketServer.shared.stopServer()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}

// MARK: - Private
private extension AppDelegate {

    func setupWindowConstraints() {
        // 少し遅延させてウィンドウが確実に作成されてから実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApplication.shared.windows.first else { return }
            window.minSize = NSSize(width: 500, height: 500)
            window.maxSize = NSSize(width: 800, height: 800)
            window.setContentSize(NSSize(width: 500, height: 500))
        }
    }
}
