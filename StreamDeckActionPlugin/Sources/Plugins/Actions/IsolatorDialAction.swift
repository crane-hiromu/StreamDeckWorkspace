//
//  IsolatorDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import StreamDeck

// MARK: - Action
final class IsolatorDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Isolator"
    static var uuid: String = "isolatordial.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .volumedial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Frequency",
        push: "Reset"
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // 画面に数値を出したかったが、処理が複雑になるので一旦出していない
        setFeedback([IsolatorDialType.currentValue.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildFrequencyDialMessage(
            type: .dialRotate,
            channel: .main, // non related
            coordinates: payload.coordinates,
            frequency: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([VolumeDialType.currentVolume.key: ""])

        let message = MessageBuilder.buildFrequencyDialMessage(
            type: .dialDown,
            channel: .main, // non related
            coordinates: payload.coordinates,
            frequency: 0
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialUp(device: String, payload: EncoderPressEvent<Settings>) {
        // NOP
    }

    func dialUp(device: String, payload: EncoderPressEvent<Settings>, longPress: Bool) {
        // NOP
    }
}

