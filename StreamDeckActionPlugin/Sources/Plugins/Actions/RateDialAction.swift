//
//  RateDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// MARK: - Action
final class RateDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Rate Control"
    static var uuid: String = "ratedial.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .volumedial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Rate",
        push: "Reset"
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
    }

    func didReceiveGlobalSettings() {
        // NOP
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // 画面に音量を出したかったが、処理が複雑になるので一旦出していない
        setFeedback([RateDialType.currentVolume.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialRotate,
            command: .changeRate,
            rate: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([RateDialType.currentVolume.key: ""])

        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialDown,
            command: .changeRate
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
