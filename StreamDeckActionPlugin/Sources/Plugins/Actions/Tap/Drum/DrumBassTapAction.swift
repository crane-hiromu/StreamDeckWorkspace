//
//  DrumBassTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumBassTapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Bass Sound" }
    static var actionUUID: String { "drum.bass.tap" }
    static var actionTitle: String { "Drum\nBass" }
    static var soundType: MessageBuilder.SoundType { .drumBass }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
