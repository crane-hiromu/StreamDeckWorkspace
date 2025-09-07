//
//  DrumSnareWTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumSnareWTapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Snare W Sound" }
    static var actionUUID: String { "drum.snare.w.tap" }
    static var actionTitle: String { "Drum\nSnare W" }
    static var soundType: MessageBuilder.SoundType { .drumSnareW }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
