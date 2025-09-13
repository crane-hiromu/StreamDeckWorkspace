//
//  EffectInfoEndTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class EffectInfoEndTapAction: EffectTapActionProtocol {
    typealias Settings = NoSettings

    // MARK: - EffectTapActionProtocol
    var effectSound: MessageBuilder.SoundType { .infoEnd }
    var actionName: String { "Effect Info End Sound" }
    var actionUUID: String { "effect.info.end.tap" }
    var buttonTitle: String { "Effect\nInfo End" }

    // MARK: - KeyAction
    static var name: String { "Effect Info End Sound" }
    static var uuid: String { "effect.info.end.tap" }

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
