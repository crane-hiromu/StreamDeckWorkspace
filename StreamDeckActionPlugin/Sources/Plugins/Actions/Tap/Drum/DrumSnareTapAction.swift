//
//  DrumSnareTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumSnareTapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Snare Sound" }
    static var actionUUID: String { "drum.snare.tap" }
    static var actionTitle: String { "Drum\nSnare" }
    static var soundType: MessageBuilder.SoundType { .drumSnareS }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
