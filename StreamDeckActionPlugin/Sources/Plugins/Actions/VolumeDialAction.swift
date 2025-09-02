//
//  VolumeDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/02.
//

import Foundation
import StreamDeck

// MARK: - Action
final class VolumeDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Volume Control"
    static var uuid: String = "volumedial.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .volumedial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Volume",
        push: "Mute"
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
        setFeedback([VolumeDialType.currentVolume.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialRotate,
            command: .changeVolume,
            channel: .main, // non related
            coordinates: payload.coordinates,
            volume: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([VolumeDialType.currentVolume.key: ""])

        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialDown,
            command: .changeVolume,
            channel: .main, // non related
            coordinates: payload.coordinates
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
