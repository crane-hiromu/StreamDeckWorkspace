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
    static var name: String = "Dial Action 2"
    // ビルドエラーになるので必ず小文字にすること
    static var uuid: String = "dialaction.rotary"
    static var icon: String = "Icons/actionIcon"

    static var encoder: RotaryEncoder? = RotaryEncoder(
        layout: .layout(name: .dialsample),
        stackColor: "#f1184c",
        icon: "Icons/stopwatch",
        rotate: "Rotate_ac", // ホームアプリに説明が出る
        push: "Push_ac" // ホームアプリに説明が出る
    )

    static var userTitleEnabled: Bool? = false

    var context: String
    var coordinates: StreamDeck.Coordinates?

//    @GlobalSetting(\.title) var title

    required init(context: String, coordinates: StreamDeck.Coordinates?) {
        self.context = context
        self.coordinates = coordinates

        logMessage(#function, context, coordinates as Any)

        setFeedback([
            "dial-text": #function
        ])
    }

    func didReceiveGlobalSettings() {
        logMessage(#function)

//        setFeedback([
//            "dial-text": "T"
//        ])
    }

    func willAppear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
    }

    func willDisappear(context: String, payload: AppearEvent<NoSettings>) {
        logMessage(#function)
        // No call
    }

    // MARK: Dial Action

    func dialRotate(device: String, payload: EncoderEvent<Settings>) {
        logMessage(#function, payload.ticks)

        setFeedback([
            "dial-text": #function
        ])
    }

    // ダイアルのボタンを押す
    func dialDown(device: String, payload: EncoderPressEvent<Settings>) {
        logMessage(#function)

        setFeedback([
            "dial-text": #function
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
