//
//  ReverbController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/04.
//

import Foundation
import AVFoundation

/// リバーブ（AVAudioUnitReverb）を段階的に制御するコントローラ
/// - wetDryMix: 0 ... 100 %
/// - 利用可能なプロパティのみで制御
final class ReverbController {

    // MARK: Tunables

    private let wetDryMixMin: Float = 0.0
    private let wetDryMixMax: Float = 100.0
    private let wetDryMixStepSensitivity: Float = 2.0

    /// マクロ一括の感度（0〜1に掛けるゲイン）とカーブ（>1で弱く、<1で強く）
    private let macroGain: Float = 0.8
    private let macroCurve: Float = 1.5

    // MARK: State

    private var wetDryMixByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]
    private var enabledByChannel: [AdvancedSoundPlayer.Channel: Bool] = [:]

    // MARK: Public

    func setEnabled(_ enabled: Bool, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) {
        enabledByChannel[channel] = enabled
        node.bypass = !enabled
    }

    func set(wetDryMix: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) {
        let v = max(min(wetDryMix, wetDryMixMax), wetDryMixMin)
        wetDryMixByChannel[channel] = v
        node.wetDryMix = v
        ServerMessageSender.shared.sendReverbChange(channel: channel.rawValue, reverb: Int(v))
    }

    /// マクロ制御用（累積値を上書きしない）
    func setMacroOnly(wetDryMix: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) {
        let v = max(min(wetDryMix, wetDryMixMax), wetDryMixMin)
        node.wetDryMix = v
        ServerMessageSender.shared.sendReverbChange(channel: channel.rawValue, reverb: Int(v))
    }

    /// ダイヤル等のステップ入力で wetDryMix を変更
    @discardableResult
    func changeWetDryMix(step: Int, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) -> Float {
        // 初期化されていない場合は0から開始
        let current = wetDryMixByChannel[channel] ?? 0.0
        // step の正負に応じて値を増減
        let delta = Float(step) * wetDryMixStepSensitivity
        let next = max(current + delta, 0.0)  // 0以下にはならない
        
        // リバーブを有効化してから値を設定
        setEnabled(true, on: channel, node: node)
        set(wetDryMix: next, on: channel, node: node)
        return next
    }

    func reset(on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) {
        wetDryMixByChannel[channel] = 0.0
        enabledByChannel[channel] = false
        node.wetDryMix = 0.0
        node.bypass = true
        ServerMessageSender.shared.sendReverbChange(channel: channel.rawValue, reverb: 0)
    }

    // MARK: Macro control

    /// k ∈ [-1, 1] を受け取り、wetDryMix を一括設定
    /// - マクロ一括の感度（0〜1に掛けるゲイン）とカーブ（>1で弱く、<1で強く）
    ///   - wetDryMix: 5% → 60% を線形
    func setMacro(k: Float, on channel: AdvancedSoundPlayer.Channel, node: AVAudioUnitReverb) {
        let clamped = max(min(k, 1.0), -1.0)
        let aRaw = abs(clamped)
        // カーブとゲインで弱める（小さく・滑らかに）
        let a = min(1.0, pow(aRaw, macroCurve) * macroGain)

        // wetDryMix: 5%〜60%
        let mix = 5.0 + 55.0 * a

        setEnabled(true, on: channel, node: node)
        setMacroOnly(wetDryMix: Float(mix), on: channel, node: node)
    }
}
