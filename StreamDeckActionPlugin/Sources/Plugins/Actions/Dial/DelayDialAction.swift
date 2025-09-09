//
//  DelayDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import StreamDeck

// MARK: - Action
final class DelayDialAction: EncoderAction, EffectDialActionProtocol {
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
    
    // 動的チャンネル（デフォルトは現在のチャンネル）
    var channel: MessageBuilder.ChannelType { ChannelManager.shared.getCurrentChannel() }

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        configure()
    }

    // MARK: Dial Action

    func willAppear(device: String, payload: AppearEvent<Settings>) {
        updateUI()
    }

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            delay: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    // MARK: Common

    func configure() {
        addEffectChangeObserver(.delayChanged, entityType: DelayChangeEntity.self)
        addChannelChangeObserver()
    }
    
    func updateEffectValue<T: ServerMessageEntity>(entity: T) {
        guard let delayEntity = entity as? DelayChangeEntity else { return }
        EffectValueStore.shared.setDelay(delayEntity.delay, for: channel)
    }
    
    func updateUI() {
        let value = EffectValueStore.shared.getDelay(for: channel)
        setFeedback([DelayDialType.currentValue.key: "\(value)"])
    }
}
