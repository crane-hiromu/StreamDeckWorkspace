//
//  PitchDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import StreamDeck

// MARK: - Action
final class PitchDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Pitch"
    static var uuid: String = "pitchdial.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .pitchdial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Pitch",
        push: "Reset"
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?
    
    // 動的チャンネル（デフォルトは現在のチャンネル）
    var channel: MessageBuilder.ChannelType { ChannelManager.shared.getCurrentChannel() }

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // 画面にピッチを出したかったが、処理が複雑になるので一旦出していない
        setFeedback([PitchDialType.currentPitch.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildPitchDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            pitch: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([PitchDialType.currentPitch.key: ""])

        let message = MessageBuilder.buildPitchDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
