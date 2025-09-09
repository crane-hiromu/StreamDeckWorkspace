//
//  VolumeDialActionProtocol.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

/// ボリューム調整用のDialActionの共通プロトコル
protocol VolumeDialActionProtocol: EncoderAction, EffectDialActionProtocol
    where Settings == NoSettings {

    static var layoutName: LayoutName { get }
    var channel: MessageBuilder.ChannelType { get }
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
        updateUI()
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
        addEffectChangeObserver(.volumeChanged, entityType: VolumeChangeEntity.self)
        addChannelChangeObserver()
    }
    
    func updateEffectValue<T: ServerMessageEntity>(entity: T) {
        guard let volumeEntity = entity as? VolumeChangeEntity else { return }
        EffectValueStore.shared.setChannelVolume(volumeEntity.volume, for: channel)
    }
    
    func updateUI() {
        let value = EffectValueStore.shared.getChannelVolume(for: channel)
        setFeedback([VolumeDialType.currentVolume.key: "\(value)"])
    }
}
