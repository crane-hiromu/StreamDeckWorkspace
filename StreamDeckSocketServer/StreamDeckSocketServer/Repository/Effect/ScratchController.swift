//
//  ScratchController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import AVFoundation

/// スクラッチ機能を制御するコントローラ
/// - レート変更とピッチ補正によるスクラッチ効果
/// - 慣性効果とバウンス効果の実装
final class ScratchController {

    // MARK: - Properties

    /// スクラッチ状態
    private var isScratching = false
    private var scratchTimer: Timer?
    private var lastScratchValue: Float = 0.0

    // MARK: - Public Methods

    /// スクラッチ開始（-1.0 〜 1.0の値で制御）
    /// - Parameters:
    ///   - value: スクラッチの強度（-1.0: 最大逆再生, 0.0: 停止, 1.0: 最大順再生）
    ///   - pitchNode: 制御対象のAVAudioUnitTimePitch
    ///   - channel: チャンネル情報（ログ用）
    func startScratch(value: Float, pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        let clampedValue = max(-1.0, min(1.0, value))
        
        // スクラッチ状態を更新
        isScratching = true
        lastScratchValue = clampedValue
        
        // レート計算（より自然なスクラッチ感）
        let rate = calculateScratchRate(from: clampedValue)
        pitchNode.rate = rate
        
        // ピッチ補正（レート変更によるピッチ変化を軽減）
        pitchNode.pitch = calculatePitchCompensation(for: rate)
        
        print("🎛️ [Channel \(channel.rawValue+1)] Scratch: \(clampedValue) -> rate: \(rate)")
    }
    
    /// スクラッチ停止（通常再生に戻す）
    /// - Parameters:
    ///   - pitchNode: 制御対象のAVAudioUnitTimePitch
    ///   - channel: チャンネル情報（ログ用）
    func stopScratching(pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        guard isScratching else { return }
        
        isScratching = false
        
        // スムーズに通常再生に戻す
        animateToNormalPlayback(pitchNode: pitchNode, channel: channel)
    }
    
    /// スクラッチ値の更新（リアルタイム制御用）
    /// - Parameters:
    ///   - value: スクラッチ値
    ///   - pitchNode: 制御対象のAVAudioUnitTimePitch
    ///   - channel: チャンネル情報（ログ用）
    func updateScratch(value: Float, pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        guard isScratching else { return }
        startScratch(value: value, pitchNode: pitchNode, channel: channel)
    }
    
    /// スクラッチの慣性をシミュレート（より自然なスクラッチ感）
    /// - Parameters:
    ///   - value: スクラッチ値
    ///   - sensitivity: 感度調整（デフォルト: 1.0）
    ///   - pitchNode: 制御対象のAVAudioUnitTimePitch
    ///   - channel: チャンネル情報（ログ用）
    func scratchWithInertia(value: Float, sensitivity: Float = 1.0, pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        let adjustedValue = value * sensitivity
        startScratch(value: adjustedValue, pitchNode: pitchNode, channel: channel)
        
        // 慣性効果：値が0に近い場合は徐々に減速
        if abs(adjustedValue) < 0.3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.stopScratching(pitchNode: pitchNode, channel: channel)
            }
        }
    }
    
    /// スクラッチのバウンス効果
    /// - Parameters:
    ///   - value: スクラッチ値
    ///   - pitchNode: 制御対象のAVAudioUnitTimePitch
    ///   - channel: チャンネル情報（ログ用）
    func scratchWithBounce(value: Float, pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        let clampedValue = max(-1.0, min(1.0, value))
        
        // バウンス効果のための振動
        let bounceSteps = 5
        let bounceDuration = 0.1
        
        for i in 0..<bounceSteps {
            let delay = Double(i) * bounceDuration
            let bounceValue = clampedValue * (1.0 - Float(i) / Float(bounceSteps))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.startScratch(value: bounceValue, pitchNode: pitchNode, channel: channel)
            }
        }
        
        // 最終的に停止
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(bounceSteps) * bounceDuration) { [weak self] in
            self?.stopScratching(pitchNode: pitchNode, channel: channel)
        }
    }
    
    /// スクラッチ中かどうか
    var scratching: Bool {
        return isScratching
    }
    
    // MARK: - Private Methods
    
    /// スクラッチ値からレートを計算
    private func calculateScratchRate(from value: Float) -> Float {
        // より自然なスクラッチ感のための非線形変換
        if abs(value) < 0.1 {
            return 1.0  // 中央付近は通常再生
        }
        
        // 指数関数的な変化でより自然なスクラッチ感
        let sign = value > 0 ? 1.0 : -1.0
        let absValue = abs(value)
        let exponentialRate = pow(absValue, 0.7) * 3.0  // 0.7乗でより滑らかに
        
        return 1.0 + (Float(sign) * exponentialRate)
    }
    
    /// レート変更によるピッチ補正を計算
    private func calculatePitchCompensation(for rate: Float) -> Float {
        // レートが1.0から離れるほどピッチを調整
        let rateDiff = rate - 1.0
        return -rateDiff * 200.0  // セント単位で補正
    }
    
    /// 通常再生にスムーズに戻す
    private func animateToNormalPlayback(pitchNode: AVAudioUnitTimePitch, channel: AdvancedSoundPlayer.Channel) {
        let currentRate = pitchNode.rate
        let currentPitch = pitchNode.pitch
        
        // アニメーション用のタイマー
        var animationStep: Float = 0.0
        let totalSteps: Float = 20.0
        let stepDuration = 0.02  // 20ms間隔
        
        scratchTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            animationStep += 1.0
            
            if animationStep >= totalSteps {
                // アニメーション完了
                pitchNode.rate = 1.0
                pitchNode.pitch = 0.0
                timer.invalidate()
                self?.scratchTimer = nil
                print("🎵 [Channel \(channel.rawValue+1)] Returned to normal playback")
            } else {
                // スムーズに補間
                let progress = animationStep / totalSteps
                let easeOut = 1.0 - pow(1.0 - progress, 3.0)  // ease-out cubic
                
                pitchNode.rate = currentRate + (1.0 - currentRate) * easeOut
                pitchNode.pitch = currentPitch + (0.0 - currentPitch) * easeOut
            }
        }
    }
}
