//
//  ToneETapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneETapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "E" }
    var japaneseName: String { "ミ" }
    
    static var name: String = "Tone E (Mi)"
    static var uuid: String = "tone.e.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
