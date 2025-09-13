//
//  EffectPufTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class EffectPufTapAction: EffectTapActionProtocol {
    typealias Settings = NoSettings

    // MARK: - EffectTapActionProtocol
    var effectSound: MessageBuilder.SoundType { .puf }
    var actionName: String { "Effect Puf Sound" }
    var actionUUID: String { "effect.puf.tap" }
    var buttonTitle: String { "Effect\nPuf" }

    // MARK: - KeyAction
    static var name: String { "Effect Puf Sound" }
    static var uuid: String { "effect.puf.tap" }

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
