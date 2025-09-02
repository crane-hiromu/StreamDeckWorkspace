//
//  AdvancedSoundPlayer.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation
import AVFoundation

// MARK: - Advanced Sound Player Error
enum AdvancedSoundPlayerError: Int, Error {
    case engineCreationFailed = -1
    case audioFileNotFound = -2
    case audioEngineNotFound = -3
    
    var localizedDescription: String {
        switch self {
        case .engineCreationFailed:
            return "Failed to create audio engine"
        case .audioFileNotFound:
            return "Audio file not found"
        case .audioEngineNotFound:
            return "Audio engine not found"
        }
    }
    
    var nsError: NSError {
        NSError(
            domain: "AdvancedSoundPlayer",
            code: rawValue,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
}

// MARK: - Advanced Player (Pitch Preservation)
final class AdvancedSoundPlayer {
    static let shared = AdvancedSoundPlayer()

    // レート調整用定数
    private static let rateMin: Float = 0.5
    private static let rateMax: Float = 3.0
    private static let rateBase: Float = 1.2

    // チャンネル
    enum Channel: Int, CaseIterable {
        case main, sub, two, three, four, other
    }

    // エンジンとチャンネル別ノード
    private var audioEngine: AVAudioEngine?
    private var playerNodes: [Channel: AVAudioPlayerNode] = [:]
    private var pitchNodes: [Channel: AVAudioUnitTimePitch] = [:]
    private var currentFiles: [Channel: AVAudioFile] = [:]
    private var cumulativeSteps: [Channel: Float] = [:]

    private init() {}

    // MARK: - Public API

    func play(
        named soundName: String,
        ext: String = "mp3",
        on channel: Channel,
        rate: Float = 1.0,
        loop: Bool = false
    ) {
        do {
            let audioFile = try setupAudioFile(named: soundName, ext: ext)
            let nodes = try ensureNodes(for: channel, format: audioFile.processingFormat)
            // レート設定（ピッチ保持）
            setupRate(nodes: nodes, channel: channel, rate: rate)
            // 既存再生の処理
            if handleExistingPlayback(nodes: nodes, audioFile: audioFile, channel: channel, loop: loop) {
                return
            }
            // 初回再生の開始
            startPlayback(nodes: nodes, audioFile: audioFile, channel: channel, loop: loop)
            
            print("🎵 [Channel \(channel.rawValue+1)] Playing \(soundName) rate=\(rate) loop=\(loop)")

        } catch {
            print("❌ Failed to play on channel \(channel): \(error)")
        }
    }

    // ステップ値から再生レートを算出（等比スケール）
    static func rate(for step: Int) -> Float {
        let clampedStep = max(min(step, 8), -8)
        let computed = powf(Self.rateBase, Float(clampedStep))
        return min(max(computed, Self.rateMin), Self.rateMax)
    }

    // ステップ指定でレート変更（感度1/5・累積可逆）
    func changeRate(on channel: Channel, step: Int) {
        let rawDelta = max(min(step, 8), -8)
        guard rawDelta != 0 else { return }
        let attenuated = Float(rawDelta) / 5.0

        let current = cumulativeSteps[channel] ?? 0
        let updated = max(min(current + attenuated, 24.0), -24.0)
        cumulativeSteps[channel] = updated

        let computed = powf(Self.rateBase, updated)
        let clamped = min(max(computed, Self.rateMin), Self.rateMax)
        setRate(on: channel, rate: clamped)
    }

    // 直接レート変更
    func setRate(on channel: Channel, rate: Float) {
        guard let pitch = pitchNodes[channel],
              let player = playerNodes[channel],
              player.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        pitch.rate = rate
        if rate > 0 {
            cumulativeSteps[channel] = logf(rate) / logf(Self.rateBase)
        }
        print("🎵 [Channel \(channel.rawValue+1)] rate -> \(rate)")
    }

    // レートをデフォルト(1.0)に戻す（指定チャンネル）
    func resetRate(on channel: Channel) {
        setRate(on: channel, rate: 1.0)
        cumulativeSteps[channel] = 0
    }

    // 現在の再生速度を取得
    func currentRate(on channel: Channel) -> Float {
        pitchNodes[channel]?.rate ?? 1.0
    }

    // 再生中かどうか確認
    func isPlaying(on channel: Channel) -> Bool {
        playerNodes[channel]?.isPlaying ?? false
    }

    // 停止（指定チャンネル）
    func stop(_ channel: Channel) {
        playerNodes[channel]?.stop()
        // state cleanup for the channel (engineは維持)
        currentFiles[channel] = nil
        cumulativeSteps[channel] = 0
    }

    // 全停止
    func stopAll() {
        playerNodes.values.forEach { $0.stop() }
        currentFiles.removeAll()
        cumulativeSteps.removeAll()
    }

    // 全チャンネルのレートをデフォルトに戻す
    func resetAllRates() {
        Channel.allCases.forEach { ch in
            resetRate(on: ch)
        }
    }

    // MARK: - Private helpers

    /**
     * オーディオエンジンが存在しない場合に作成します
     * 
     * - Throws: エンジン作成に失敗した場合にエラーを投げます
     */
    private func ensureEngine() throws {
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
    }

    /**
     * 指定されたチャンネルのオーディオノードを確保します
     * 
     * - Parameters:
     *   - channel: ノードを確保するチャンネル
     *   - format: オーディオフォーマット
     * - Returns: プレイヤーノードとピッチノードのタプル
     * - Throws: エンジンが存在しない場合にエラーを投げます
     * 
     * - Note: 既存のノードが存在する場合はそれを返し、存在しない場合は新規作成します
     */
    private func ensureNodes(
        for channel: Channel,
        format: AVAudioFormat
    ) throws -> (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch) {

        if let player = playerNodes[channel], let pitch = pitchNodes[channel] {
            return (player, pitch)
        }
        guard let engine = audioEngine else {
            throw AdvancedSoundPlayerError.audioEngineNotFound.nsError
        }

        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        engine.attach(player)
        engine.attach(pitch)

        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: engine.mainMixerNode, format: format)

        playerNodes[channel] = player
        pitchNodes[channel] = pitch
        return (player, pitch)
    }

    /**
     * オーディオファイルをスケジュールして再生を開始します
     * 
     * - Parameters:
     *   - nodes: プレイヤーノードとピッチノードのタプル
     *   - audioFile: 再生するオーディオファイル
     *   - channel: 再生するチャンネル
     *   - loop: ループ再生するかどうか
     *
     * - Note: ループ再生の場合は完了時のコールバックを設定しません
     */
    private func scheduleAndPlay(
        nodes: (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch),
        audioFile: AVAudioFile,
        channel: Channel,
        loop: Bool
    ) {
        if loop {
            nodes.player.scheduleFile(audioFile, at: nil)
        } else {
            nodes.player.scheduleFile(audioFile, at: nil) { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.stop(channel)
                }
            }
        }
        
        nodes.player.play()
    }

    /**
     * オーディオファイルをセットアップします
     */
    private func setupAudioFile(named soundName: String, ext: String) throws -> AVAudioFile {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            throw AdvancedSoundPlayerError.audioFileNotFound.nsError
        }
        
        try ensureEngine()
        guard let engine = audioEngine else {
            throw AdvancedSoundPlayerError.audioEngineNotFound.nsError
        }
        
        return try AVAudioFile(forReading: url)
    }
    
    /**
     * レート設定を行います
     */
    private func setupRate(
        nodes: (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch),
        channel: Channel,
        rate: Float
    ) {
        nodes.pitch.rate = rate
        cumulativeSteps[channel] = 0 < rate ? (logf(rate) / logf(Self.rateBase)) : 0
    }
    
    /**
     * 既存の再生がある場合の処理を行います
     * 
     * - Returns: 既存再生を処理した場合はtrue、初回再生の場合はfalse
     */
    private func handleExistingPlayback(
        nodes: (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch),
        audioFile: AVAudioFile,
        channel: Channel,
        loop: Bool
    ) -> Bool {
        guard nodes.player.isPlaying else { return false }
        nodes.player.stop()
        // 停止後に少し待ってから再スケジュール
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.scheduleAndPlay(nodes: nodes, audioFile: audioFile, channel: channel, loop: loop)
        }
        return true
    }
    
    /**
     * 初回再生を開始します
     */
    private func startPlayback(
        nodes: (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch),
        audioFile: AVAudioFile,
        channel: Channel,
        loop: Bool
    ) {
        // エンジン起動（既に起動ならOK）
        if let engine = audioEngine, !engine.isRunning {
            try? engine.start()
        }
        
        // エンジン起動後にスケジュールと再生
        scheduleAndPlay(nodes: nodes, audioFile: audioFile, channel: channel, loop: loop)
    }
}
