//
//  DelayController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import AVFoundation

/// ディレイ（AVAudioUnitDelay）を段階的に制御するコントローラ
/// - time: 0.0 ... 2.0 秒
/// - feedback: 0 ... 100 %
/// - wetDryMix: 0 ... 100 %
final class DelayController {

    // MARK: Tunables

    private let timeMin: Float = 0.0
    private let timeMax: Float = 2.0
    private let timeStepSensitivity: Float = 0.02   // 1ステップあたり約 20ms

    private let feedbackMin: Float = 0.0
    private let feedbackMax: Float = 95.0           // ハウリング防止でやや控えめ
    private let feedbackStepSensitivity: Float = 5.0

    private let mixMin: Float = 0.0
    private let mixMax: Float = 80.0
    private let mixStepSensitivity: Float = 8.0

    /// マクロ一括の感度（0〜1に掛けるゲイン）とカーブ（>1で弱く、<1で強く）
    private let macroGain: Float = 0.6
    private let macroCurve: Float = 2.0

    // MARK: State

    private var timeByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var feedbackByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var mixByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var enabledByChannel: [AdvancedSoundPlayer.Channel: Bool] = [:]

    // MARK: Public

    func setEnabled(_ enabled: Bool, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        enabledByChannel[channel] = enabled
        node.bypass = !enabled
        print("🎛️ [Delay] Channel \(channel) enabled -> \(enabled), bypass -> \(node.bypass)")
    }

    func set(time: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(time, timeMax), timeMin)
        timeByChannel[channel] = v
        node.delayTime = TimeInterval(v)
    }

    func set(feedback: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(feedback, feedbackMax), feedbackMin)
        feedbackByChannel[channel] = v
        node.feedback = v
        print("🎛️ [Delay] Channel \(channel) feedback -> \(v)%")
    }

    func set(wetDryMix: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(wetDryMix, mixMax), mixMin)
        mixByChannel[channel] = v
        node.wetDryMix = v
        print("🎛️ [Delay] Channel \(channel) wetDryMix -> \(v)%")
    }

    /// ダイヤル等のステップ入力で time を変更
    @discardableResult
    func changeTime(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        let clamped = Float(max(min(step, 8), -8))
        let current = timeByChannel[channel] ?? 0.3
        let next = max(min(current + clamped * timeStepSensitivity, timeMax), timeMin)
        set(time: next, on: channel, node: node)
        return next
    }

    /// ダイヤル等のステップ入力で feedback を変更
    @discardableResult
    func changeFeedback(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        // 初期化されていない場合は20%から開始
        let current = feedbackByChannel[channel] ?? 20.0
        // step の正負に応じて値を増減
        let delta = Float(step) * feedbackStepSensitivity
        let next = max(min(current + delta, feedbackMax), feedbackMin)
        
        // ディレイを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(time: 0.1, on: channel, node: node)  // 固定のディレイ時間を設定
        set(wetDryMix: 40.0, on: channel, node: node)  // 適切なwetDryMix値を設定
        set(feedback: next, on: channel, node: node)
        return next
    }

    /// ダイヤル等のステップ入力で wetDryMix を変更
    @discardableResult
    func changeMix(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        // 初期化されていない場合は25%から開始
        let current = mixByChannel[channel] ?? 25.0
        // step の正負に応じて値を増減
        let delta = Float(step) * mixStepSensitivity
        let next = max(min(current + delta, mixMax), mixMin)
        
        // ディレイを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(time: 0.1, on: channel, node: node)  // 固定のディレイ時間を設定
        set(feedback: 30.0, on: channel, node: node)  // 適切なfeedback値を設定
        set(wetDryMix: next, on: channel, node: node)
        return next
    }

    func reset(on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        timeByChannel[channel] = 0.0
        feedbackByChannel[channel] = 0.0
        mixByChannel[channel] = 0.0
        enabledByChannel[channel] = false
        node.delayTime = 0.0
        node.feedback = 0.0
        node.wetDryMix = 0.0
        node.lowPassCutoff = 15000 // デフォルト維持
        node.bypass = true
    }

    // MARK: Macro control

    /// k ∈ [-1, 1] を受け取り、time/feedback/mix を一括設定
    /// - マッピング例:
    ///   - time: 固定（約 100ms）にして変化を感じにくくする
    ///   - feedback: 15% → 70% を線形
    ///   - mix: 20% → 80% を線形
    func setMacro(k: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let clamped = max(min(k, 1.0), -1.0)
        let aRaw = abs(clamped)
        // カーブとゲインで弱める（小さく・滑らかに）
        let a = min(1.0, pow(aRaw, macroCurve) * macroGain)

        // time: 固定（スラップバック系の浅いディレイ感）
        let timeF: Float = 0.1

        // feedback: 15%〜70% / mix: 20%〜80%
        let fb = 15.0 + 55.0 * a
        let mx = 20.0 + 60.0 * a

        setEnabled(true, on: channel, node: node)
        set(time: timeF, on: channel, node: node)
        set(feedback: Float(fb), on: channel, node: node)
        set(wetDryMix: Float(mx), on: channel, node: node)
    }
}


