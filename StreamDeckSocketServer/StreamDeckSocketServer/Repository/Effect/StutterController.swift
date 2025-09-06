//
//  StutterController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import AVFoundation

/// ストッター機能を制御するコントローラ
/// - 指定された秒数分の音をループで流し、ボタンで切り替え
/// - ストッター中は指定された長さのセグメントを繰り返し再生
final class StutterController {

    // MARK: - Properties

    /// ストッター状態
    private var isStuttering = false
    private var stutterTimer: Timer?
    private var stutterSegmentLength: Double = 0.25 // デフォルト0.25秒
    private var stutterStartTime: Double = 0.0 // ストッター開始時の再生位置
    private var originalLoopState: Bool = false // 元のループ状態を保存
    
    /// ストッター用のバッファ（指定された長さの音声データを保存）
    private var stutterBuffer: AVAudioPCMBuffer?
    
    /// ストッター開始時のファイル
    private var stutterStartFile: AVAudioFile?
    
    /// ストッター開始時のループ状態
    private var stutterStartLoop: Bool = false
    
    // MARK: - Public Methods

    /// ストッター開始（指定された秒数分の音をループで流す）
    /// - Parameters:
    ///   - segmentLength: ストッターのセグメント長（秒）
    ///   - playerNode: 制御対象のAVAudioPlayerNode
    ///   - channel: チャンネル情報（ログ用）
    ///   - currentTime: 現在の再生位置
    ///   - audioFile: 再生中のオーディオファイル
    func startStutter(segmentLength: Double, 
                     playerNode: AVAudioPlayerNode, 
                     channel: AdvancedSoundPlayer.Channel,
                     currentTime: Double,
                     audioFile: AVAudioFile) {
        
        // ストッター状態を更新
        isStuttering = true
        stutterSegmentLength = max(0.05, min(2.0, segmentLength)) // 0.05〜2.0秒の範囲で制限
        stutterStartTime = currentTime
        stutterStartFile = audioFile
        
        print("🎛️ [Channel \(channel.rawValue+1)] Stutter started: \(segmentLength)s → \(stutterSegmentLength)s segment")

        // 現在の再生を停止
        playerNode.stop()
        
        // ストッター用のバッファを作成（現在の再生位置から）
        createStutterBuffer(from: audioFile, startTime: currentTime, length: stutterSegmentLength)
        
        // ストッターループを開始
        startStutterLoop(playerNode: playerNode, channel: channel)
    }
    
    /// ストッター停止（通常再生に戻す）
    /// - Parameters:
    ///   - playerNode: 制御対象のAVAudioPlayerNode
    ///   - channel: チャンネル情報（ログ用）
    func stopStutter(playerNode: AVAudioPlayerNode, channel: AdvancedSoundPlayer.Channel) {
        guard isStuttering else { return }
        
        isStuttering = false
        stutterTimer?.invalidate()
        stutterTimer = nil
        
        // ストッターを停止して通常再生を再開
        playerNode.stop()
    }
    
    /// ストッター中かどうか
    var stuttering: Bool {
        return isStuttering
    }
    
    /// ストッターのセグメント長を取得
    var currentSegmentLength: Double {
        return stutterSegmentLength
    }
    
    // MARK: - Private Methods
    
    /// ストッター用のバッファを作成
    private func createStutterBuffer(from audioFile: AVAudioFile, startTime: Double, length: Double) {
        let format = audioFile.processingFormat
        let sampleRate = format.sampleRate
        let frameCount = UInt32(length * sampleRate)
        
        print("🎛️ Creating stutter buffer: length=\(length)s, frames=\(frameCount), sampleRate=\(sampleRate)")
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to create stutter buffer")
            return
        }
        
        do {
            // ループ対応：ファイル長で割った余りを使用
            let fileDuration = Double(audioFile.length) / sampleRate
            let actualStartTime = startTime.truncatingRemainder(dividingBy: fileDuration)
            
            // 指定された位置から指定された長さ分の音声データを読み込み
            audioFile.framePosition = AVAudioFramePosition(actualStartTime * sampleRate)
            try audioFile.read(into: buffer, frameCount: frameCount)
            stutterBuffer = buffer
        } catch {
            print("❌ Failed to read audio data for stutter: \(error)")
        }
    }
    
    /// ストッターループを開始
    private func startStutterLoop(playerNode: AVAudioPlayerNode, channel: AdvancedSoundPlayer.Channel) {
        guard let buffer = stutterBuffer else {
            print("❌ No stutter buffer available")
            return
        }
        
        // 複数のバッファを事前にスケジュールして継続性を確保
         // 100個のバッファを事前にスケジュール。100回なると止まる。
        let bufferCount = 100
        
        for _ in 0..<bufferCount {
            if buffer.format.channelCount == playerNode.outputFormat(forBus: 0).channelCount {
                playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                    // ストッター中なら次のバッファをスケジュール
                    if self?.isStuttering == true {
                        DispatchQueue.main.async {
                            self?.scheduleNextStutterBuffer(playerNode: playerNode, channel: channel)
                        }
                    }
                })
            }
        }
        
        // 再生開始
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    /// 次のストッターバッファをスケジュール
    private func scheduleNextStutterBuffer(playerNode: AVAudioPlayerNode, channel: AdvancedSoundPlayer.Channel) {
        guard isStuttering, let buffer = stutterBuffer else { return }
        
        if buffer.format.channelCount == playerNode.outputFormat(forBus: 0).channelCount {
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                // ストッター中なら次のバッファをスケジュール
                if self?.isStuttering == true {
                    DispatchQueue.main.async {
                        self?.scheduleNextStutterBuffer(playerNode: playerNode, channel: channel)
                    }
                }
            })
        }
    }
    
    /// ストッターのセグメント長を変更
    func updateSegmentLength(_ newLength: Double) {
        stutterSegmentLength = max(0.05, min(2.0, newLength))
    }
    
    /// ストッター開始時の位置を取得
    func getStutterStartTime() -> Double {
        return stutterStartTime
    }
    
    /// ストッター開始時のファイルを取得
    func getStutterStartFile() -> AVAudioFile? {
        return stutterStartFile
    }
    
    /// ストッター開始時のループ状態を設定
    func setStutterStartLoop(_ isLoop: Bool) {
        stutterStartLoop = isLoop
    }
    
    /// ストッター開始時のループ状態を取得
    func getStutterStartLoop() -> Bool {
        return stutterStartLoop
    }
    
    /// ストッターをリセット
    func reset() {
        isStuttering = false
        stutterTimer?.invalidate()
        stutterTimer = nil
        stutterBuffer = nil
        stutterStartTime = 0.0
        originalLoopState = false
        stutterStartFile = nil
        stutterStartLoop = false
    }
}
