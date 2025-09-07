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

            setFeedback([VolumeDialType.currentVolume.key: "\(entity.volume)"])
        }
    }
}
