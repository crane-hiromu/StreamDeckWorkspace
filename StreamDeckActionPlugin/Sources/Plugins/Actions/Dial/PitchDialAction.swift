//
//  PitchDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import StreamDeck

// MARK: - Action
final class PitchDialAction: EncoderAction, EffectDialActionProtocol {
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
        configure()
    }

    // MARK: Life Cycle

    func willAppear(device: String, payload: AppearEvent<Settings>) {
        updateUI()
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        let message = MessageBuilder.buildPitchDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            pitch: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        let message = MessageBuilder.buildPitchDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}

// MARK: - EffectDialActionProtocol
extension PitchDialAction {
    
    func configure() {
        addEffectChangeObserver(.pitchChanged, entityType: PitchChangeEntity.self)
        addChannelChangeObserver()
    }
    
    func updateEffectValue<T: ServerMessageEntity>(entity: T) {
        guard let pitchEntity = entity as? PitchChangeEntity else { return }
        EffectValueStore.shared.setPitch(pitchEntity.pitch, for: channel)
    }
    
    func updateUI() {
        let value = EffectValueStore.shared.getPitch(for: channel)
        setFeedback([PitchDialType.currentPitch.key: "\(value)"])
    }
}
