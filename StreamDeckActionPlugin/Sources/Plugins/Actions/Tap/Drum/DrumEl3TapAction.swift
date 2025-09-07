//
//  DrumEl3TapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumEl3TapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Electronic 3 Sound" }
    static var actionUUID: String { "drum.el3.tap" }
    static var actionTitle: String { "Drum\nEl 3" }
    static var soundType: MessageBuilder.SoundType { .drumEl3 }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
