//
//  ToneATapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneATapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "A" }
    var japaneseName: String { "ラ" }
    
    static var name: String = "Tone A (La)"
    static var uuid: String = "tone.a.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
