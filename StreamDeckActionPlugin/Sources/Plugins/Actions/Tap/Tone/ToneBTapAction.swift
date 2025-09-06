//
//  ToneBTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneBTapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "B" }
    var japaneseName: String { "シ" }
    
    static var name: String = "Tone B (Si)"
    static var uuid: String = "tone.b.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
