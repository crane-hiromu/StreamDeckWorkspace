//
//  ToneController.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/01/27.
//

import Foundation
import AVFoundation

/// トーン再生を管理するコントローラクラス
/// AdvancedSoundPlayerからTone Generationの責任を分離
final class ToneController {
    
    // MARK: - Properties
    
    private let toneGenerator = ToneGenerator()
    private var tonePlayer: AVAudioPlayerNode?
    private weak var audioEngine: AVAudioEngine?
    
    // MARK: - Initialization
    
    init() {
        // トーン生成器の音声バッファを事前生成（遅延を最小化）
        toneGenerator.pregenerateAllTones()
    }
    
    // MARK: - Public Methods
    
    /// 指定された音階を再生（低遅延）
    func playTone(_ note: String) throws {
        guard let buffer = toneGenerator.getAudioBuffer(for: note) else {
            throw ToneControllerError.bufferGenerationFailed
        }
        
        // トーン専用のシンプルなプレイヤーを使用
        try ensureTonePlayer()
        
        guard let player = tonePlayer else {
            throw ToneControllerError.playerNotAvailable
        }
        
        // 既存の再生を停止（即座に）
        player.stop()
        
        // バッファを直接再生（確実に再生）
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        player.play()
        print("🎵 Playing tone \(note)")
    }
    
    /// 利用可能な音階のリストを取得
    var availableTones: [String] {
        return toneGenerator.availableNotes
    }
    
    /// オーディオエンジンを設定（外部から注入）
    func setAudioEngine(_ engine: AVAudioEngine) {
        self.audioEngine = engine
    }
    
    // MARK: - Private Methods
    
    /// トーン専用プレイヤーを確保
    private func ensureTonePlayer() throws {
        if tonePlayer == nil {
            guard let engine = audioEngine else {
                throw ToneControllerError.audioEngineNotSet
            }
            
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            // 直接メインミキサーに接続（シンプル構成）
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
            engine.connect(player, to: engine.mainMixerNode, format: format)
            
            if !engine.isRunning {
                try engine.start()
            }
            
            tonePlayer = player
        }
    }
}

// MARK: - ToneControllerError

enum ToneControllerError: Error, LocalizedError {
    case bufferGenerationFailed
    case playerNotAvailable
    case audioEngineNotSet
    
    var errorDescription: String? {
        switch self {
        case .bufferGenerationFailed:
            return "Failed to generate audio buffer for tone"
        case .playerNotAvailable:
            return "Tone player is not available"
        case .audioEngineNotSet:
            return "Audio engine is not set"
        }
    }
}
