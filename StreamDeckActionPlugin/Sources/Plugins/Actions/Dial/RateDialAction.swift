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

    static var name: String = "Rate"
    static var uuid: String = "ratedial.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .ratedial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Rate",
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
        let message = MessageBuilder.buildRateDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            rate: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        let message = MessageBuilder.buildRateDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}
