//
//  ReverbDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/05.
//

import Foundation
import StreamDeck

// MARK: - Action
final class ReverbDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Reverb"
    static var uuid: String = "reverb.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .reverbDial),
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

    // MARK: Life Cycle

    func willAppear(device: String, payload: AppearEvent<Settings>) {
        updateValue()
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // 画面に数値を出したかったが、処理が複雑になるので一旦出していない
        setFeedback([ReverbDialType.currentValue.key: payload.ticks > 0 ? "+" : "-"])

        let message = MessageBuilder.buildReverbDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            reverb: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        setFeedback([ReverbDialType.currentValue.key: ""])

        let message = MessageBuilder.buildReverbDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}

// MARK: - Private
private extension ReverbDialAction {

    func configure() {
        NotificationCenter.default.addObserver(
            forName: .reverbChanged,
            object: nil,
            queue: .main
        ) { [weak self] nofi in
            guard let self else { return }
            let data = nofi.userInfo?[MessageReceiver.entityKey]
            guard let entity = data as? ReverbChangeEntity else { return }

            let type = MessageBuilder.ChannelType(rawValue: entity.channel)
            guard type == self.channel else { return }

            // 値を保存してからUI反映
            EffectValueStore.shared.setReverb(entity.reverb, for: self.channel)
            self.setFeedback([ReverbDialType.currentValue.key: "\(entity.reverb)"])
        }

        NotificationCenter.default.addObserver(
            forName: .channelChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateValue()
        }
    }

    func updateValue() {
        let value = EffectValueStore.shared.getReverb(for: channel)
        setFeedback([ReverbDialType.currentValue.key: "\(value)"])
    }
}
