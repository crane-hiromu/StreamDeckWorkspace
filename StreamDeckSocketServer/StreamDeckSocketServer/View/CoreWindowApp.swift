//
//  CoreWindowApp.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import SwiftUI

// MARK: - Root Window
@main
struct CoreWindowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 500, maxWidth: 800, minHeight: 500, maxHeight: 800)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 500)
    }
}
