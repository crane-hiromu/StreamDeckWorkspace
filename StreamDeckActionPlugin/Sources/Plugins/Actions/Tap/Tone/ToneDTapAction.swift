//
//  ToneDTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneDTapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "D" }
    var japaneseName: String { "レ" }
    
    static var name: String = "Tone D (Re)"
    static var uuid: String = "tone.d.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
