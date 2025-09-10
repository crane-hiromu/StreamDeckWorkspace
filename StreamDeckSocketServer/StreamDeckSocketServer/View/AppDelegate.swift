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
    }

    func applicationWillTerminate(_ notification: Notification) {
        UnixSocketServer.shared.stopServer()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
