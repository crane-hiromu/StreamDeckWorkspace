//
//  ToneCTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneCTapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "C" }
    var japaneseName: String { "ド" }
    
    static var name: String = "Tone C (Do)"
    static var uuid: String = "tone.c.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
