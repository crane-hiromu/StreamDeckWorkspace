//
//  FlangerController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import AVFoundation

/// フランジャー（AVAudioUnitDelay + 高音強調）を段階的に制御するコントローラ
/// - delayTime: 0.005 ... 0.05 秒
/// - feedback: 0 ... 100 %
/// - wetDryMix: 0 ... 100 %
/// - highFreqBoost: 0 ... 20 dB（高音域ブースト）
final class FlangerController {

    // MARK: Tunables

    private let delayTimeMin: Double = 0.001  // 1ms（極短いディレイで激しいジェット効果）
    private let delayTimeMax: Double = 0.015  // 15ms（より短い範囲で集中）
    private let delayTimeStepSensitivity: Double = 0.002  // より細かい調整

    private let feedbackMin: Float = 0.0
    private let feedbackMax: Float = 100.0
    private let feedbackStepSensitivity: Float = 8.0     // 1つまみで8%変化

    private let wetDryMixMin: Float = 0.0
    private let wetDryMixMax: Float = 100.0
    private let wetDryMixStepSensitivity: Float = 5.0    // 1つまみで5%変化

    private let highFreqBoostMin: Float = 0.0
    private let highFreqBoostMax: Float = 20.0
    private let highFreqBoostStepSensitivity: Float = 2.0  // 1つまみで2dB変化

    /// マクロ一括の感度（0〜1に掛けるゲイン）とカーブ（>1で弱く、<1で強く）
    private let macroGain: Float = 1.0
    private let macroCurve: Float = 1.2

    // MARK: State

    private var delayTimeByChannel: [AdvancedSoundPlayer.Channel: Double] = [:]
    private var feedbackByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var wetDryMixByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var highFreqBoostByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var enabledByChannel: [AdvancedSoundPlayer.Channel: Bool] = [:]

    // MARK: Public

    func setEnabled(_ enabled: Bool, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        enabledByChannel[channel] = enabled
        node.bypass = !enabled
        
        // 初回有効化時にディレイ設定
        if enabled {
            node.delayTime = 0.005  // 5ms（極短いディレイで激しいジェット効果）
            node.feedback = 70.0    // 70%（より強いフィードバック）
            node.wetDryMix = 10.0   // 20%（控えめな初期値）
        }
    }

    func set(delayTime: Double, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(delayTime, delayTimeMax), delayTimeMin)
        delayTimeByChannel[channel] = v
        node.delayTime = v
    }

    func set(feedback: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(feedback, feedbackMax), feedbackMin)
        feedbackByChannel[channel] = v
        node.feedback = v
    }

    func set(wetDryMix: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(wetDryMix, wetDryMixMax), wetDryMixMin)
        wetDryMixByChannel[channel] = v
        node.wetDryMix = v
        ServerMessageSender.shared.sendFlangerChange(channel: channel.rawValue, flanger: Int(v))
    }

    func set(highFreqBoost: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let v = max(min(highFreqBoost, highFreqBoostMax), highFreqBoostMin)
        highFreqBoostByChannel[channel] = v
    }

    /// ダイヤル等のステップ入力で delayTime を変更
    @discardableResult
    func changeDelayTime(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Double {
        // 初期化されていない場合は5msから開始
        let current = delayTimeByChannel[channel] ?? 0.005
        // step の正負に応じて値を増減
        let delta = Double(step) * delayTimeStepSensitivity
        let next = max(min(current + delta, delayTimeMax), delayTimeMin)
        
        // フランジャーを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(delayTime: next, on: channel, node: node)

        return next
    }

    /// ダイヤル等のステップ入力で feedback を変更
    @discardableResult
    func changeFeedback(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        // 初期化されていない場合は70%から開始
        let current = feedbackByChannel[channel] ?? 70.0
        // step の正負に応じて値を増減
        let delta = Float(step) * feedbackStepSensitivity
        let next = max(min(current + delta, feedbackMax), feedbackMin)
        
        // フランジャーを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(feedback: next, on: channel, node: node)

        return next
    }

    /// ダイヤル等のステップ入力で wetDryMix を変更
    @discardableResult
    func changeWetDryMix(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        // 初期化されていない場合は20%から開始
        let current = wetDryMixByChannel[channel] ?? 20.0
        // step の正負に応じて値を増減
        let delta = Float(step) * wetDryMixStepSensitivity
        let next = max(min(current + delta, wetDryMixMax), wetDryMixMin)
        
        // フランジャーを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(wetDryMix: next, on: channel, node: node)

        return next
    }

    /// ダイヤル等のステップ入力で highFreqBoost を変更
    @discardableResult
    func changeHighFreqBoost(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) -> Float {
        // 初期化されていない場合は10dBから開始
        let current = highFreqBoostByChannel[channel] ?? 10.0
        // step の正負に応じて値を増減
        let delta = Float(step) * highFreqBoostStepSensitivity
        let next = max(min(current + delta, highFreqBoostMax), highFreqBoostMin)
        
        // フランジャーを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(highFreqBoost: next, on: channel, node: node)

        return next
    }

    func reset(on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        delayTimeByChannel[channel] = 0.005
        feedbackByChannel[channel] = 70.0
        wetDryMixByChannel[channel] = 10.0
        highFreqBoostByChannel[channel] = 10.0
        enabledByChannel[channel] = false
        
        node.delayTime = 0.005
        node.feedback = 70.0
        node.wetDryMix = 10.0
        node.bypass = true
        ServerMessageSender.shared.sendFlangerChange(channel: channel.rawValue, flanger: 0)
    }

    // MARK: Macro control

    /// k ∈ [-1, 1] を受け取り、delayTime/feedback/wetDryMix を一括設定
    /// - マクロ一括の感度（0〜1に掛けるゲイン）とカーブ（>1で弱く、<1で強く）
    ///   - delayTime: 5ms → 80ms を線形
    ///   - feedback: 20% → 80% を線形
    ///   - wetDryMix: 30% → 90% を線形
    func setMacro(k: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitDelay) {
        let clamped = max(min(k, 1.0), -1.0)
        let aRaw = abs(clamped)
        // カーブとゲインで弱める（小さく・滑らかに）
        let a = min(1.0, pow(aRaw, macroCurve) * macroGain)

        // delayTime: 1ms〜15ms（より短い範囲で激しい効果）
        let delayTime = 0.001 + 0.014 * a
        // feedback: 40%〜100%（より高いフィードバック）
        let feedback = 40.0 + 60.0 * a
        // wetDryMix: 50%〜100%（より強いエフェクト）
        let wetDryMix = 50.0 + 50.0 * a
        // highFreqBoost: 5dB〜20dB（より強い高音強調）
        let highFreqBoost = 5.0 + 15.0 * a

        setEnabled(true, on: channel, node: node)
        set(delayTime: Double(delayTime), on: channel, node: node)
        set(feedback: Float(feedback), on: channel, node: node)
        set(wetDryMix: Float(wetDryMix), on: channel, node: node)
        set(highFreqBoost: Float(highFreqBoost), on: channel, node: node)
    }
}
