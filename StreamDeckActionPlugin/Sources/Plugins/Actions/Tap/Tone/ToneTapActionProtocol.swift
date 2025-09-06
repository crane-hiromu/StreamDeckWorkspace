//
//  ToneTapActionProtocol.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

/// トーン再生用のTapActionの共通プロトコル
protocol ToneTapActionProtocol: KeyAction where Settings == NoSettings {
    var note: String { get }
    var japaneseName: String { get }
}

extension ToneTapActionProtocol {

    static var icon: String { "Icons/actionIcon" }
    
    static var states: [PluginActionState]? {
        [PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)]
    }
    
    static var userTitleEnabled: Bool? { false }
    
    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        let message = MessageBuilder.buildToneTapMessage(
            type: .keyDown,
            command: .playTone,
            channel: .keyboard,
            coordinates: coordinates,
            note: note
        )
        UnixSocketClient.shared.sendMessage(message)
        
        print("🎵 Playing tone: \(note) (\(japaneseName))")
    }
    
    func updateTitle() {
        setTitle(to: "\(note)\n\(japaneseName)")
    }
}
