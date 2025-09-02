//
//  AdvancedSoundPlayer.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation
import AVFoundation

// MARK: - Advanced Player (Pitch Preservation)
final class AdvancedSoundPlayer {
    static let shared = AdvancedSoundPlayer()
    
    // レート調整用定数
    private static let rateMin: Float = 0.5
    private static let rateMax: Float = 3.0
    private static let rateBase: Float = 1.2
    // 累積ステップ（回転の総和を保持して可逆性を担保）
    private var cumulativeStep: Float = 0

    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var timePitchNode: AVAudioUnitTimePitch?
    private var currentAudioFile: AVAudioFile?
    
    private init() {}
    
    func playSoundWithPitchPreservation(named soundName: String, 
                                       ext: String = "mp3",
                                       rate: Float = 1.0) {

        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            print("❌ Audio file not found: \(soundName)")
            return
        }
        
        do {
            // 既存のエンジンを停止・クリーンアップ
            stopAndCleanup()
            
            // オーディオエンジンをセットアップ
            audioEngine = AVAudioEngine()
            audioPlayerNode = AVAudioPlayerNode()
            timePitchNode = AVAudioUnitTimePitch()
            
            guard let engine = audioEngine,
                  let playerNode = audioPlayerNode,
                  let timePitch = timePitchNode else { 
                print("❌ Failed to create audio components")
                return 
            }
            
            // オーディオファイルを読み込み
            currentAudioFile = try AVAudioFile(forReading: url)
            guard let audioFile = currentAudioFile else { return }
            
            // ノードを接続
            engine.attach(playerNode)
            engine.attach(timePitch)
            
            engine.connect(playerNode, to: timePitch, format: audioFile.processingFormat)
            engine.connect(timePitch, to: engine.mainMixerNode, format: audioFile.processingFormat)
            
            // 速度変更（ピッチは保持）
            timePitch.rate = rate
            // 現在のレートから累積ステップを初期化
            if rate > 0 {
                cumulativeStep = logf(rate) / logf(Self.rateBase)
            } else {
                cumulativeStep = 0
            }
            
            // エンジンを開始
            try engine.start()
            
            // 再生開始
            playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
                // 再生完了時の処理
                DispatchQueue.main.async {
                    self?.stopAndCleanup()
                }
            }
            playerNode.play()
            
            print("🎵 Playing \(soundName) with rate: \(rate) (pitch preserved)")
            
        } catch {
            print("❌ Failed to play with pitch preservation: \(error)")
        }
    }
        
    // ステップ値から再生レートを算出（等比スケール）
    static func rate(for step: Int) -> Float {
        let clampedStep = max(min(step, 8), -8)
        let computed = powf(Self.rateBase, Float(clampedStep))
        return min(max(computed, Self.rateMin), Self.rateMax)
    }
    
    // ステップ指定でレート変更（感度1/5・累積可逆）
    func changeRate(step: Int) {
        let rawDelta = max(min(step, 8), -8)
        guard rawDelta != 0 else { return }

        // 感度を1/5に減衰（符号維持）
        let attenuated = Float(rawDelta) / 5.0

        // 累積してからレート算出（左右回転で可逆）
        cumulativeStep = max(min(cumulativeStep + attenuated, 24.0), -24.0)
        let computed = powf(Self.rateBase, cumulativeStep)
        let clamped = min(max(computed, Self.rateMin), Self.rateMax)
        changeRate(clamped)
    }

    // 再生中の速度変更
    private func changeRate(_ rate: Float) {
        guard let timePitch = timePitchNode,
              let playerNode = audioPlayerNode,
              playerNode.isPlaying else {
            print("❌ No audio playing or components not available")
            return
        }
        timePitch.rate = rate
        print("🎵 Playback rate changed to: \(rate)")
    }

    // 速度をデフォルト値に戻す
    func resetRate() {
        changeRate(1.0)
        cumulativeStep = 0
    }

    // 現在の再生速度を取得
    func getCurrentRate() -> Float {
        timePitchNode?.rate ?? 1.0
    }
    
    // 再生中かどうか確認
    func isPlaying() -> Bool {
        audioPlayerNode?.isPlaying ?? false
    }
    
    // 停止
    func stop() {
        audioPlayerNode?.stop()
        stopAndCleanup()
    }
    
    // プライベートメソッド
    private func stopAndCleanup() {
        audioPlayerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        audioPlayerNode = nil
        timePitchNode = nil
        currentAudioFile = nil
    }
}
