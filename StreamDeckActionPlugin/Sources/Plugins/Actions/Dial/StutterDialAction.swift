//
//  StutterDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import StreamDeck

// MARK: - Action
final class StutterDialAction: EncoderAction {
    typealias Settings = NoSettings

    static var name: String = "Stutter"
    static var uuid: String = "stutter.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .stutterDial),
        stackColor: "#ff6b35",
        icon: "Icons/loop",
        rotate: "Length",
        push: "Reset"
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?
    
    // 動的チャンネル（デフォルトは現在のチャンネル）
    var channel: MessageBuilder.ChannelType { ChannelManager.shared.getCurrentChannel() }
    
    // 現在のセグメント長をローカルで管理（他のアクションからもアクセス可能）
    static var currentSegmentLength: Double = 0.25

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        updateUI()
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        // ダイヤルアクションはセグメント長の調整（加算式）
        // ノブを回すと0.05秒ずつ増減（0.05〜2.0秒の範囲）
        let increment = Double(payload.ticks) * 0.05
        StutterDialAction.currentSegmentLength = max(0.05, min(2.0, StutterDialAction.currentSegmentLength + increment))
        
        updateUI()

        let message = MessageBuilder.buildStutterDialMessage(
            type: .dialRotate,
            channel: channel,
            coordinates: payload.coordinates,
            segmentLength: StutterDialAction.currentSegmentLength
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        // ダイヤルプッシュはセグメント長をデフォルト（0.25秒）にリセット
        StutterDialAction.currentSegmentLength = 0.25
        
        updateUI()

        let message = MessageBuilder.buildStutterDialMessage(
            type: .dialDown,
            channel: channel,
            coordinates: payload.coordinates,
            segmentLength: StutterDialAction.currentSegmentLength
        )
        UnixSocketClient.shared.sendMessage(message)
    }

    func updateUI() {
        let value = String(format: "%.2fs", StutterDialAction.currentSegmentLength)
        setFeedback([StutterDialType.segmentLength.key: value])
    }
}
