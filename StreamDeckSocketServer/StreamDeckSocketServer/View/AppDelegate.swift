import Cocoa
import SwiftUI

// MARK: - AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Property

    private let socketServer = UnixSocketServer()

    // MARK: Delegate Method

    func applicationDidFinishLaunching(_ notification: Notification) {
        socketServer.startServer()
        // オーディオエンジンを事前起動（初回再生の遅延を回避）
        AdvancedSoundPlayer.shared.prewarmAudioEngine()
        ServerMessageSender.shared.setUnixSocketServer(socketServer)
    }

    func applicationWillTerminate(_ notification: Notification) {
        socketServer.stopServer()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
