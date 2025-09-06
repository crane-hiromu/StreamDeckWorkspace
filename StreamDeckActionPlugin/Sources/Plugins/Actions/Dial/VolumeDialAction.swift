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

    static var name: String = "Volume"
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
        configure()
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialRotate,
            channel: .main, // non related
            coordinates: payload.coordinates,
            volume: payload.ticks
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        let message = MessageBuilder.buildVolumeDialMessage(
            type: .dialDown,
            channel: .main, // non related
            coordinates: payload.coordinates
        )
        UnixSocketClient.shared.sendMessage(message)
    }
}

// MARK: - Private
private extension VolumeDialAction {

    func configure() {
        NotificationCenter.default.addObserver(
            forName: .volumeChanged,
            object: nil,
            queue: .main
        ) { [weak self] nofi in
            let data = nofi.userInfo?[MessageReceiver.entityKey]
            guard let entity = data as? VolumeChangeEntity else { return }
            // todo channel 判定
            self?.setFeedback([VolumeDialType.currentVolume.key: "\(entity.volume)"])
        }
    }
}
