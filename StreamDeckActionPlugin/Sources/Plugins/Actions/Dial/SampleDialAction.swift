//
//  SampleDialAction.swift
//  StreamDeckActionPlugin
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation
import StreamDeck

// MARK: - Action
class SampleDialAction: EncoderAction {
    typealias Settings = NoSettings

    // ダイアル画面に表示されるタイトル
    static var name: String = "Sample Dial"
    // ビルドエラーになるので必ず小文字にすること
    static var uuid: String = "dialaction.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .sampledial),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Rotate_ac", // ホームアプリに説明が出る
        push: "Push_ac" // ホームアプリに説明が出る
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates

        logMessage(#function, context, coordinates as Any)

        setFeedback([
            SampleDialType.text.key: #function
        ])
    }

    func didReceiveGlobalSettings() {
        logMessage(#function)
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        logMessage(#function, payload.ticks)

        setFeedback([
            SampleDialType.text.key: #function
        ])
    }

    // ダイアルのボタンを押す
    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        logMessage(#function)

        setFeedback([
            SampleDialType.text.key: #function
        ])
    }

    // ダイアルのボタンを押す（`dialDown`後に呼ばれる）
    func dialUp(device: String, payload: EncoderPressEvent<Settings>) {
        logMessage(#function)
    }

    // ダイアルのボタンを押す（通常の`dialUp`後に呼ばれる）
    func dialUp(device: String, payload: EncoderPressEvent<Settings>, longPress: Bool) {
        logMessage(#function, longPress)
    }
}
