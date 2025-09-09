//
//  IsolatorController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import AVFoundation

/// 1ノブ・アイソレーター（LOW/MID/HIGH）の制御を担うコントローラ
/// - バランス値 s ∈ [-1, 1] を保持し、EQ 3バンドへ対称にブースト/カットを適用
final class IsolatorController {

    // チャンネル毎のバランス状態（-1.0: 低音側、+1.0: 高音側）
    private var balanceByChannel: [AdvancedSoundPlayer.Channel: Float] = [:]

    // MARK: Factory
    /// 3バンドEQ（LOW/MID/HIGH）を生成
    func makeEQ() -> AVAudioUnitEQ {
        let eq = AVAudioUnitEQ(numberOfBands: 3)
        guard eq.bands.count >= 3 else { return eq }

        // LOW (LowShelf)
        let low = eq.bands[0]
        low.filterType = .lowShelf
        low.frequency = 200
        low.bandwidth = 0.7
        low.gain = 0
        low.bypass = false

        // MID (Parametric)
        let mid = eq.bands[1]
        mid.filterType = .parametric
        mid.frequency = 1000
        mid.bandwidth = 1.0
        mid.gain = 0
        mid.bypass = false

        // HIGH (HighShelf)
        let high = eq.bands[2]
        high.filterType = .highShelf
        high.frequency = 10000
        high.bandwidth = 0.7
        high.gain = 0
        high.bypass = false

        return eq
    }

    // MARK: Public API

    /// ステップ入力からバランスを更新（-1...1）し、EQへ適用
    func updateBalance(on channel: AdvancedSoundPlayer.Channel, eq: AVAudioUnitEQ, step: Int, sensitivity: Float = 1.0/20.0) {
        let delta = Float(step) * sensitivity
        let current = balanceByChannel[channel] ?? 0
        let clamped = max(min(current + delta, 1.0), -1.0)
        balanceByChannel[channel] = clamped
        apply(eq: eq, state: clamped)
    }

    /// 直接バランスを設定（スムージングあり）
    func setBalance(on channel: AdvancedSoundPlayer.Channel, eq: AVAudioUnitEQ, value: Float, smoothing: Float = 0.15) {
        let target = max(min(value, 1.0), -1.0)
        let current = balanceByChannel[channel] ?? 0
        let k = max(0.0, min(smoothing, 1.0))
        let blended = current + (target - current) * k
        balanceByChannel[channel] = blended
        apply(eq: eq, state: blended)
    }

    /// リセット（フラット）
    func reset(on channel: AdvancedSoundPlayer.Channel, eq: AVAudioUnitEQ) {
        balanceByChannel[channel] = 0
        guard eq.bands.count >= 3 else { return }
        eq.bands[0].gain = 0
        eq.bands[1].gain = 0
        eq.bands[2].gain = 0
    }

    /// 指定チャンネルの現在のバランス値を取得
    func getBalance(for channel: AdvancedSoundPlayer.Channel) -> Float {
        return balanceByChannel[channel] ?? 0
    }

    // MARK: Private
    /// バランス状態からLOW/MID/HIGHのゲインを計算して適用
    private func apply(eq: AVAudioUnitEQ, state s: Float) {
        guard eq.bands.count >= 3 else { return }

        func boost(_ x: Float) -> Float { return 24.0 * powf(x, 1.6) }   // dB
        func cut(_ x: Float)   -> Float { return -60.0 * powf(x, 1.2) }  // dB

        let pos = max(0,  s)   // 高音側
        let neg = max(0, -s)   // 低音側

        // 反対側も比例カットする対称マッピング
        let lowGain  = neg > 0 ? boost(neg) : cut(pos)
        let highGain = pos > 0 ? boost(pos) : cut(neg)
        let midGain  = cut(abs(s))

        eq.bands[0].gain = lowGain
        eq.bands[1].gain = midGain
        eq.bands[2].gain = highGain
    }
}
