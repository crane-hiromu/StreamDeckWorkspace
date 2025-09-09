//
//  VolumeDialActionProtocol.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

/// ボリューム調整用のDialActionの共通プロトコル
protocol VolumeDialActionProtocol: EncoderAction where Settings == NoSettings {
    static var layoutName: LayoutName { get }
    var channel: MessageBuilder.ChannelType? { get }
}

extension VolumeDialActionProtocol {

    static var icon: String { "Icons/actionIcon" }

    static var encoder: RotaryEncoder? {
        RotaryEncoder(
            layout: layoutName,
            stackColor: "#f1184c",
            icon: "Icons/stopwatch",
            rotate: "Volume",
            push: "Mute"
        )
    }

    static var userTitleEnabled: Bool? { false }

    // MARK: Life Cycle

    func willAppear(device: String, payload: AppearEvent<Settings>) {
        updateValue()
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<NoSettings>) {
        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            volume: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<NoSettings>) {
        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    // MARK: Common

    func configure() {
        NotificationCenter.default.addObserver(
            forName: .volumeChanged,
            object: nil,
            queue: .main
        ) { nofi in
            let data = nofi.userInfo?[MessageReceiver.entityKey]
            guard let entity = data as? VolumeChangeEntity else { return }

            let type = MessageBuilder.ChannelType(rawValue: entity.channel)
            guard type == channel else { return }

            // 値を保存してからUI反映
            if let type { EffectValueStore.shared.setChannelVolume(entity.volume, for: type) }
            setFeedback([VolumeDialType.currentVolume.key: "\(entity.volume)"])
        }

        NotificationCenter.default.addObserver(
            forName: .channelChanged,
            object: nil,
            queue: .main
        ) { _ in
            updateValue()
        }
    }

    func updateValue() {
        guard let channel else { return }
        let value = EffectValueStore.shared.getChannelVolume(for: channel)
        setFeedback([VolumeDialType.currentVolume.key: "\(value)"])
    }
}
