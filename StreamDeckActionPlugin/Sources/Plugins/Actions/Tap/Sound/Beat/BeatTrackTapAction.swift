//
//  BeatTrackTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class BeatTrackTapAction: SoundTapAction {
    typealias Settings = NoSettings

    static var actionName: String { "Beat Track Sound" }
    static var actionUUID: String { "beattrack.tap" }
    static var actionTitle: String { "Beat\nTrack" }
    static var soundType: MessageBuilder.SoundType { .beat }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setDefaultTitle()
    }
}

