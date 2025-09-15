//
//  EffectHornTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by assistant on 2025/09/15.
//

import Foundation
import StreamDeck

// MARK: - Action
final class EffectHornTapAction: EffectTapActionProtocol {
    typealias Settings = NoSettings

    // MARK: - EffectTapActionProtocol
    var effectSound: MessageBuilder.SoundType { .horn }
    var actionName: String { "Effect Horn Sound" }
    var actionUUID: String { "effect.horn.tap" }
    var buttonTitle: String { "Effect\nHorn" }

    // MARK: - KeyAction
    static var name: String { "Effect Horn Sound" }
    static var uuid: String { "effect.horn.tap" }

    var context: String
    var coordinates: Coordinates?

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setupEffectAction()
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        handleEffectKeyDown()
    }
}


