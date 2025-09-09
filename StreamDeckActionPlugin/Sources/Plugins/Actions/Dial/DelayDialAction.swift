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
    
    // 動的チャンネル（デフォルトは現在のチャンネル）
    var channel: MessageBuilder.ChannelType { ChannelManager.shared.getCurrentChannel() }

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        configure()
    }

    // MARK: Dial Action

    func willAppear(device: String, payload: AppearEvent<Settings>) {
        updateValue()
    }

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // 画面に数値を出したかったが、処理が複雑になるので一旦出していない
        setFeedback([DelayDialType.currentValue.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            delay: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([DelayDialType.currentValue.key: ""])

        let message = MessageBuilder.buildDelayDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    // MARK: Common

    func configure() {
        NotificationCenter.default.addObserver(
            forName: .delayChanged,
            object: nil,
            queue: .main
        ) { [weak self] nofi in
            guard let self else { return }
            let data = nofi.userInfo?[MessageReceiver.entityKey]
            guard let entity = data as? DelayChangeEntity else { return }

            let type = MessageBuilder.ChannelType(rawValue: entity.channel)
            guard type == self.channel else { return }

            EffectValueStore.shared.setDelay(entity.delay, for: self.channel)
            self.setFeedback([DelayDialType.currentValue.key: "\(entity.delay)"])
        }

        NotificationCenter.default.addObserver(
            forName: .channelChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateValue()
        }
    }

    // MARK: Helpers

    private func updateValue() {
        let value = EffectValueStore.shared.getDelay(for: channel)
        setFeedback([DelayDialType.currentValue.key: "\(value)"])
    }
}
