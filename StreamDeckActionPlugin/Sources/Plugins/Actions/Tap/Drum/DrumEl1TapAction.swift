//
//  DrumEl1TapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumEl1TapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Electronic 1 Sound" }
    static var actionUUID: String { "drum.el1.tap" }
    static var actionTitle: String { "Drum\nEl 1" }
    static var soundType: MessageBuilder.SoundType { .drumEl1 }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
