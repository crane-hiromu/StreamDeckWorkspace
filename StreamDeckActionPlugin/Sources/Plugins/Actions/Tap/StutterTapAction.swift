//
//  StutterTapAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/01/27.
//

import StreamDeck
import OSLog

// MARK: - Action
final class StutterTapAction: KeyAction {
    typealias Settings = NoSettings

    static var name: String = "Stutter Tap"
    static var uuid: String = "stuttertap.tap"
    static var icon: String = "Icons/actionIcon"

    static var states: [PluginActionState]? = [
        PluginActionState(image: "Icons/actionDefaultImage", titleAlignment: .middle)
    ]

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: Coordinates?

    private var stuttering: Bool = false
    
    // セグメント長を共有（StutterDialActionと同期）
    private var segmentLength: Double {
        return StutterDialAction.currentSegmentLength
    }

    required init(context: String, coordinates: Coordinates?) {
        self.context = context
        self.coordinates = coordinates
        setTitle(to: "Stutter")
    }

    func keyDown(device: String, payload: KeyEvent<NoSettings>) {
        // タップアクションはストッターの開始/停止のみ
        let message = MessageBuilder.buildStutterTapMessage(
            type: .keyDown,
            command: .stutter,
            channel: ChannelManager.shared.getCurrentChannel(),
            segmentLength: segmentLength, // デフォルト値を使用
            coordinates: coordinates
        )
        UnixSocketClient.shared.sendMessage(message)

        stuttering.toggle()
    }
}
