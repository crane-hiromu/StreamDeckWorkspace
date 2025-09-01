//
//  SocketHelper.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - Socket Helper
final class SocketHelper {
    
    // MARK: - Static Methods
    
    /// sockaddr_unポインタをsockaddrポインタにキャストする
    /// - Parameter ptr: sockaddr_unのポインタ
    /// - Returns: sockaddrのポインタ
    static func sockaddr_cast(_ ptr: UnsafePointer<sockaddr_un>) -> UnsafePointer<sockaddr> {
        UnsafeRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
    }
    
    /// sockaddr_unの可変ポインタをsockaddrの可変ポインタにキャストする
    /// - Parameter ptr: sockaddr_unの可変ポインタ
    /// - Returns: sockaddrの可変ポインタ
    static func sockaddr_cast_mutable(_ ptr: UnsafeMutablePointer<sockaddr_un>) -> UnsafeMutablePointer<sockaddr> {
        UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: sockaddr.self)
    }
    
    /// sockaddr_unのサイズをsocklen_tとして取得する
    /// - Returns: sockaddr_unのサイズ
    static func sockaddr_un_size() -> socklen_t {
        socklen_t(MemoryLayout<sockaddr_un>.size)
    }
    
    /// Int32のサイズをsocklen_tとして取得する
    /// - Returns: Int32のサイズ
    static func int32_size() -> socklen_t {
        socklen_t(MemoryLayout<Int32>.size)
    }
    
    /// バイト配列からUTF-8文字列をパースする
    /// - Parameter buffer: バイト配列
    /// - Parameter bytesRead: 読み取ったバイト数
    /// - Returns: パースされた文字列、失敗時はnil
    static func parseUTF8String(from buffer: [UInt8], bytesRead: Int) -> String? {
        let data = Data(buffer.prefix(bytesRead))
        return String(data: data, encoding: .utf8)
    }
    
    /// readシステムコールの戻り値を判定する
    /// - Parameter bytesRead: readの戻り値
    /// - Returns: 読み取り結果の状態
    static func readResult(_ bytesRead: Int) -> ReadResult {
        if bytesRead > 0 {
            return .success(bytesRead)
        } else if bytesRead == 0 {
            return .connectionClosed
        } else {
            return .error
        }
    }
}
