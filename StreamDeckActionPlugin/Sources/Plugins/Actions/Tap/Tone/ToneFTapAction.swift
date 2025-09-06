//
//  ToneFTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ToneFTapAction: KeyAction, ToneTapActionProtocol {
    var note: String { "F" }
    var japaneseName: String { "ファ" }
    
    static var name: String = "Tone F (Fa)"
    static var uuid: String = "tone.f.tap"
    
    var context: String
    var coordinates: Coordinates?
    
    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateTitle()
    }
}
