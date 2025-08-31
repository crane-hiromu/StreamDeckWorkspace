import Cocoa
import SwiftUI

// MARK: - AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Property

    private let socketServer = UnixSocketServer()

    // MARK: Delegate Method

    func applicationDidFinishLaunching(_ notification: Notification) {
        socketServer.startServer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        socketServer.stopServer()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
