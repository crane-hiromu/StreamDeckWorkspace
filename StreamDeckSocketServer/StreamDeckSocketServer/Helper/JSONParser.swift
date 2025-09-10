//
//  JSONParser.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/05/09.
//

import Foundation

// MARK: - JSON Parser
final class JSONParser {
    
    // MARK: - Static Properties
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    // MARK: - Static Methods
    
    /// JSON文字列から指定された型にデコードする
    /// - Parameters:
    ///   - jsonString: JSON形式の文字列
    ///   - type: デコードする型
    /// - Returns: デコードされたオブジェクト、失敗時はnil
    static func decode<T: Codable>(_ jsonString: String, as type: T.Type) -> T? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let result = try decoder.decode(type, from: data)
            return result
        } catch {
            print("❌ JSON decode error: \(error)")
            return nil
        }
    }
    
    /// データから指定された型にデコードする
    /// - Parameters:
    ///   - data: JSONデータ
    ///   - type: デコードする型
    /// - Returns: デコードされたオブジェクト、失敗時はnil
    static func decode<T: Codable>(_ data: Data, as type: T.Type) -> T? {
        do {
            let result = try decoder.decode(type, from: data)
            return result
        } catch {
            print("❌ JSON decode error: \(error)")
            return nil
        }
    }
    
    /// オブジェクトをJSON文字列にエンコードする
    /// - Parameter object: エンコードするオブジェクト
    /// - Returns: JSON文字列、失敗時はnil
    static func encode<T: Codable>(_ object: T) -> String? {
        do {
            let data = try encoder.encode(object)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ JSON encode error: \(error)")
            return nil
        }
    }
    
    /// オブジェクトをJSONデータにエンコードする
    /// - Parameter object: エンコードするオブジェクト
    /// - Returns: JSONデータ、失敗時はnil
    static func encode<T: Codable>(_ object: T) -> Data? {
        do {
            let data = try encoder.encode(object)
            return data
        } catch {
            print("❌ JSON encode error: \(error)")
            return nil
        }
    }
}
