//
//  ToneGenerator.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import AVFoundation

/// ドレミファソラシの音を生成するクラス
/// 低遅延で高品質な音声生成を実現
final class ToneGenerator {
    
    // MARK: - Properties
    
    private let sampleRate: Double = 44100.0
    private let duration: Double = 0.3  // 音の長さ（秒）- 短縮してレスポンス向上
    private let amplitude: Float = 0.3  // 音量
    
    // 低遅延用の設定（ステレオフォーマット）
    private let lowLatencyFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    }()
    
    // ドレミファソラシの周波数（Hz）
    private let frequencies: [String: Double] = [
        "C": 261.63,  // ド
        "D": 293.66,  // レ
        "E": 329.63,  // ミ
        "F": 349.23,  // ファ
        "G": 392.00,  // ソ
        "A": 440.00,  // ラ
        "B": 493.88   // シ
    ]
    
    // 生成された音声バッファのキャッシュ
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    
    // MARK: - Public Methods
    
    /// 指定された音階の音声バッファを取得（キャッシュ付き）
    func getAudioBuffer(for note: String) -> AVAudioPCMBuffer? {
        // キャッシュから取得
        if let cachedBuffer = audioBuffers[note] {
            return cachedBuffer
        }
        
        // 新規生成
        guard let frequency = frequencies[note.uppercased()] else {
            print("❌ Unknown note: \(note)")
            return nil
        }
        
        let buffer = generateToneBuffer(frequency: frequency)
        audioBuffers[note] = buffer
        return buffer
    }
    
    /// 全音階のバッファを事前生成（遅延を最小化）
    func pregenerateAllTones() {
        for note in frequencies.keys {
            _ = getAudioBuffer(for: note)
        }
        print("🎵 All tone buffers pregenerated")
    }
    
    /// 音階名のリストを取得
    var availableNotes: [String] {
        return Array(frequencies.keys).sorted()
    }
    
    // MARK: - Private Methods
    
    /// 指定された周波数の音声バッファを生成
    private func generateToneBuffer(frequency: Double) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: lowLatencyFormat, frameCapacity: frameCount) else {
            print("❌ Failed to create audio buffer")
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // サイン波を生成（ステレオ）
        guard let channelData = buffer.floatChannelData else {
            print("❌ Failed to get channel data")
            return nil
        }
        
        let omega = 2.0 * Double.pi * frequency / sampleRate
        
        // 高速化のため、エンベロープを同時に適用
        let attackFrames = Int(sampleRate * 0.005)  // 5ms attack（短縮）
        let releaseFrames = Int(sampleRate * 0.05)  // 50ms release（短縮）
        
        for frame in 0..<Int(frameCount) {
            let sample = amplitude * Float(sin(omega * Double(frame)))
            
            // エンベロープを適用（低遅延のため簡略化）
            var envelope: Float = 1.0
            if frame < attackFrames {
                envelope = Float(frame) / Float(attackFrames)
            } else if frame >= Int(frameCount) - releaseFrames {
                envelope = Float(Int(frameCount) - frame) / Float(releaseFrames)
            }
            
            let finalSample = sample * envelope
            channelData[0][frame] = finalSample  // 左チャンネル
            channelData[1][frame] = finalSample  // 右チャンネル
        }
        
        return buffer
    }
    
    /// エンベロープ（音量の変化）を適用してより自然な音にする
    private func applyEnvelope(to buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        let attackFrames = Int(sampleRate * 0.01)  // 10ms attack
        let releaseFrames = Int(sampleRate * 0.1)  // 100ms release
        
        // Attack phase
        for frame in 0..<min(attackFrames, frameCount) {
            let envelope = Float(frame) / Float(attackFrames)
            channelData[frame] *= envelope
        }
        
        // Release phase
        let releaseStart = max(0, frameCount - releaseFrames)
        for frame in releaseStart..<frameCount {
            let envelope = Float(frameCount - frame) / Float(releaseFrames)
            channelData[frame] *= envelope
        }
    }
}

// MARK: - Extension for AdvancedSoundPlayer Integration

extension ToneGenerator {
    
    /// 指定された音階を指定されたチャンネルで再生
    func playNote(_ note: String, on channel: AdvancedSoundPlayer.Channel) {
        guard getAudioBuffer(for: note) != nil else {
            print("❌ Failed to get audio buffer for note: \(note)")
            return
        }
        
        // AdvancedSoundPlayerの既存システムを使用
        // 実際の実装では、PlaybackChannelに直接バッファを送信する必要があります
        print("🎵 Playing note \(note) on channel \(channel)")
    }
}
