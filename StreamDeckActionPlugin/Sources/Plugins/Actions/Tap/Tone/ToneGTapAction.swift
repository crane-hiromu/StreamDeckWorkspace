//
//  ToneGTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneGTapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "G" }
    var japaneseName: String { "ソ" }
    
    static var name: String = "Tone G (So)"
    static var uuid: String = "tone.g.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
