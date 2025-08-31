//
//  SocketDescriptor.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation

/*
 - ソケットがまだ作られていない状態（初期値やエラー時）は -1 が返る
 - socket(), bind(), accept() などが失敗すると -1 が返る
 */

// MARK: - Helper for Socket
final class SocketDescriptor {
    var value: Int32 = -1

    var isValid: Bool {
        value != -1
    }

    func reset() {
        value = -1
    }
}
