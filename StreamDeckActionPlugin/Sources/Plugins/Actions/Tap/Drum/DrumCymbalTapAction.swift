//
//  DrumCymbalTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumCymbalTapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Cymbal Sound" }
    static var actionUUID: String { "drum.cymbal.tap" }
    static var actionTitle: String { "Drum\nCymbal" }
    static var soundType: MessageBuilder.SoundType { .drumCymbal }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
