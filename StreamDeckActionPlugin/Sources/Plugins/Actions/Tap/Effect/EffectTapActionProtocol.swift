//
//  EffectTapActionProtocol.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

/**
 * 効果音タップアクション用の共通プロトコル
 * 効果音を再生するアクションの共通処理を定義します。
 */
protocol EffectTapActionProtocol: KeyAction {
    /// 再生する効果音のタイプ
    var effectSound: MessageBuilder.SoundType { get }
    
    /// アクションの表示名
    var actionName: String { get }
    
    /// アクションのUUID
    var actionUUID: String { get }
    
    /// ボタンに表示するタイトル
    var buttonTitle: String { get }
}

// MARK: - Default Implementation
extension EffectTapActionProtocol {
    
    /// 共通のアイコン設定
    static var icon: String { "Icons/actionIcon" }
    
    /// 共通の状態設定
    static var states: [PluginActionState]? {
        [PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)]
    }
    
    /// 共通のユーザータイトル設定
    static var userTitleEnabled: Bool? { false }
    
    /// 共通の初期化処理
    func setupEffectAction() {
        setTitle(to: buttonTitle)
    }
    
    /// 共通のキーダウン処理
    func handleEffectKeyDown() {
        let message = MessageBuilder.buildTapMessage(
            type: .keyDown,
            command: .playSound,
            sound: effectSound,
            channel: .sound,
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
