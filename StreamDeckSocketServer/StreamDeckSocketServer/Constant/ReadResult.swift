//
//  ReadResult.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - Read Result
/// readシステムコールの戻り値を表す列挙型
enum ReadResult {
    case success(Int)      // 成功（読み取ったバイト数）
    case connectionClosed  // 接続が閉じられた
    case error            // エラー
}
