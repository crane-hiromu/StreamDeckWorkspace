//
//  EffectInfoStartTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class EffectInfoStartTapAction: EffectTapActionProtocol {
    typealias Settings = NoSettings

    // MARK: - EffectTapActionProtocol
    var effectSound: MessageBuilder.SoundType { .infoStart }
    var actionName: String { "Effect Info Start Sound" }
    var actionUUID: String { "effect.info.start.tap" }
    var buttonTitle: String { "Effect\nInfo Start" }

    // MARK: - KeyAction
    static var name: String { "Effect Info Start Sound" }
    static var uuid: String { "effect.info.start.tap" }

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
