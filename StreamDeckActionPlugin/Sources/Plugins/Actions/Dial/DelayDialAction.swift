//
//  DelayDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DelayDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Delay"
    static var uuid: String = "delay.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .delayDial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Delay",
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
        setFeedback([DelayDialType.currentValue.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialRotate,
            channel: .main,
            coordinates: payload.coordinates,
            delay: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([DelayDialType.currentValue.key: ""])

        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialDown,
            channel: .main,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
