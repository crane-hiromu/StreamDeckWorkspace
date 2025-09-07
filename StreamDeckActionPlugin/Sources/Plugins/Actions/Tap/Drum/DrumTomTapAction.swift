//
//  DrumTomTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DrumTomTapAction: DrumTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Drum Tom Sound" }
    static var actionUUID: String { "drum.tom.tap" }
    static var actionTitle: String { "Drum\nTom" }
    static var soundType: MessageBuilder.SoundType { .drumTom }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}
