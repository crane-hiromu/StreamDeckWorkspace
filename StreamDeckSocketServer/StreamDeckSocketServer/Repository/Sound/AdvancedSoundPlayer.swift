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

    // チャンネル
    enum Channel: Int, CaseIterable {
        case main, sub, two, three, four, other
    }

    // エンジンとチャンネル管理
    private var audioEngine: AVAudioEngine?
    private var channels: [Channel: PlaybackChannel] = [:]

    private init() {}

    // MARK: - Public API
    
    /// オーディオエンジンを事前起動（初回再生の遅延を回避）
    func prewarmAudioEngine() {
        do {
            try ensureEngine()
            
            guard let engine = audioEngine else {
                print("❌ Audio engine not available")
                return
            }
            // 最低1つのチャンネルを作成してからエンジンを起動
            if channels.isEmpty {
                let dummyChannel = PlaybackChannel(channel: .main)
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
                guard let audioFormat = format else {
                    print("❌ Failed to create audio format")
                    return
                }
                try? dummyChannel.setupNodes(engine: engine, format: audioFormat)
                channels[.main] = dummyChannel
            }
            
            if !engine.isRunning {
                try engine.start()
                print("🔧 Audio engine prewarmed successfully")
            }
        } catch {
            print("❌ Failed to prewarm audio engine: \(error)")
        }
    }

    /// 指定されたチャンネルで音声ファイルを再生
    func play(named soundName: String,
              ext: String = "mp3",
              on channel: Channel,
              rate: Float = 1.0,
              loop: Bool = false) {
        do {
            let audioFile = try setupAudioFile(named: soundName, ext: ext)
            let playbackChannel = ensureChannel(for: channel, format: audioFile.processingFormat)
            // レート設定
            playbackChannel.setRate(rate)
            // 既存再生の処理
            if playbackChannel.isPlaying {
                playbackChannel.stop()
                // 停止後に少し待ってから再再生
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.playWithCallback(channel: channel, playbackChannel: playbackChannel, file: audioFile)
                }
                return
            }
            // 初回再生時は読み込みに時間がかかるため、少し待機してから再生開始
            let isFirstPlaybackForChannel = !playbackChannel.isPlaying
            if isFirstPlaybackForChannel {
                print("🔍 [DEBUG] First playback for channel \(channel) detected, waiting for engine to be ready...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.startPlaybackAfterDelay(channel: channel, playbackChannel: playbackChannel, audioFile: audioFile, loop: loop)
                }
            } else {
                startPlaybackAfterDelay(channel: channel, playbackChannel: playbackChannel, audioFile: audioFile, loop: loop)
            }
            
            print("🎵 [Channel \(channel.rawValue+1)] Playing \(soundName) rate=\(rate) loop=\(loop)")
            
        } catch {
            print("❌ Failed to play on channel \(channel): \(error)")
        }
    }

    // ステップ値から再生レートを算出（等比スケール）
    static func rate(for step: Int) -> Float {
        RateController.rate(for: step)
    }
    
    // ステップ指定でレート変更
    func changeRate(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        let newRate = playbackChannel.rateController.change(step: step)
        playbackChannel.setRate(newRate)
    }

    // 直接レート変更
    func setRate(on channel: Channel, rate: Float) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        playbackChannel.setRate(rate)
        print("🎵 [Channel \(channel.rawValue+1)] rate -> \(rate)")
    }

    // ステップ指定でピッチ変更
    func changePitch(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        let cents = playbackChannel.pitchController.change(step: step)
        playbackChannel.setPitch(cents)
    }

    // 指定されたチャンネルのピッチを変更
    func setPitch(on channel: Channel, pitch: Float) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        playbackChannel.setPitch(pitch)
        print("🎵 [Channel \(channel.rawValue+1)] pitch -> \(pitch) cents")
    }

    // レートをデフォルト(1.0)に戻す（指定チャンネル）
    func resetRate(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.rateController.reset()
        playbackChannel.setRate(1.0)
    }

    // 指定されたチャンネルのピッチをデフォルト（0セント）に戻します
    func resetPitch(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.pitchController.reset()
        playbackChannel.setPitch(0.0)
    }

    // MARK: - Loop Control

    /// 指定されたチャンネルのループ設定を変更
    func setLoop(on channel: Channel, loop: Bool) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        playbackChannel.setLoop(loop)
        print("🎵 [Channel \(channel.rawValue+1)] loop -> \(loop)")
    }

    /// 指定されたチャンネルの現在のループ設定を取得
    func isLooping(on channel: Channel) -> Bool {
        guard let playbackChannel = channels[channel] else { return false }
        return playbackChannel.looping
    }

    /// 全チャンネルのループ設定を変更
    func setAllLoops(_ loop: Bool) {
        channels.values.forEach { $0.setLoop(loop) }
        print("🎵 All channels loop -> \(loop)")
    }

    /// 全チャンネルのループ設定をリセット（false）
    func resetAllLoops() {
        channels.values.forEach { $0.setLoop(false) }
        print("🎵 All channels loop reset to false")
    }

    /// 指定されたチャンネルのループ設定を反転
    func toggleLoop(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        let newLoopState = !playbackChannel.looping
        playbackChannel.setLoop(newLoopState)
        print("🎵 [Channel \(channel.rawValue+1)] loop toggled -> \(newLoopState)")
    }

    /// 全チャンネルのループ設定を反転
    func toggleAllLoops() {
        channels.values.forEach { channel in
            let newLoopState = !channel.looping
            channel.setLoop(newLoopState)
        }
        print("🎵 All channels loop toggled")
    }

    // 現在の再生速度を取得
    func currentRate(on channel: Channel) -> Float {
        guard let playbackChannel = channels[channel] else { return 1.0 }
        return playbackChannel.pitch?.rate ?? 1.0
    }
    
    // 再生中かどうか確認
    func isPlaying(on channel: Channel) -> Bool {
        guard let playbackChannel = channels[channel] else { return false }
        return playbackChannel.isPlaying
    }

    // 停止（指定チャンネル）
    func stop(_ channel: Channel) {
        channels[channel]?.stop()
    }

    // 全停止
    func stopAll() {
        channels.values.forEach { $0.stop() }
    }

    // 全チャンネルのレートをデフォルトに戻す
    func resetAllRates() {
        channels.values.forEach { $0.rateController.reset() }
    }

    // 全チャンネルのピッチをデフォルトに戻す
    func resetAllPitch() {
        channels.values.forEach { $0.pitchController.reset() }
    }

    // MARK: - Isolator Control

    /// ノブ値（トグルの累積）を -1...1 に正規化して、LOW/MID/HIGH のゲインを更新
    func updateIsolatorBalance(on channel: Channel, step: Int, sensitivity: Float = 1.0/20.0) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.updateIsolatorBalance(step: step, sensitivity: sensitivity)
    }

    /// アイソレーター状態を直接設定（スムージング対応）
    func setIsolatorBalance(on channel: Channel, value s: Float, smoothing: Float = 0.15) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.setIsolatorBalance(value: s, smoothing: smoothing)
    }

    /// 指定チャンネルのアイソレーターをリセット（フラット）
    func resetIsolator(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.resetIsolator()
    }

    /// 全チャンネルのアイソレーターをリセット（フラット）
    func resetAllIsolators() {
        channels.values.forEach { $0.resetIsolator() }
    }

    // MARK: - Delay Control

    func enableDelay(on channel: Channel, _ enabled: Bool) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.enableDelay(enabled)
    }

    func setDelay(on channel: Channel,
                  time seconds: Float? = nil,
                  feedback percent: Float? = nil,
                  mix wetDryMix: Float? = nil) {
        guard let playbackChannel = channels[channel] else { return }
        if let seconds { playbackChannel.setDelayTime(seconds) }
        if let percent { playbackChannel.setDelayFeedback(percent) }
        if let wetDryMix { playbackChannel.setDelayMix(wetDryMix) }
    }

    func resetDelay(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.resetDelay()
    }

    func resetAllDelays() {
        channels.values.forEach { $0.resetDelay() }
    }

    /// k ∈ [-1, 1] でディレイをマクロ一括制御
    func setDelayMacro(on channel: Channel, k: Float) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.setDelayMacro(k)
    }

    // MARK: - Reverb Control

    func enableReverb(on channel: Channel, _ enabled: Bool) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.enableReverb(enabled)
    }

    func setReverb(on channel: Channel,
                   mix wetDryMix: Float? = nil) {
        guard let playbackChannel = channels[channel] else { return }
        if let wetDryMix { playbackChannel.setReverbMix(wetDryMix) }
    }

    func resetReverb(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.resetReverb()
    }

    func resetAllReverbs() {
        channels.values.forEach { $0.resetReverb() }
    }

    /// k ∈ [-1, 1] でリバーブをマクロ一括制御
    func setReverbMacro(on channel: Channel, k: Float) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.setReverbMacro(k)
    }

    /// ステップ値でリバーブのwetDryMixを変更
    func changeReverbWetDryMix(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.changeReverbWetDryMix(step)
    }

    // MARK: - Private helpers

    /// オーディオエンジンが存在しない場合に作成
    private func ensureEngine() throws {
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
    }

    /// 指定されたチャンネルのPlaybackChannelインスタンスを取得または作成
    private func ensureChannel(for channel: Channel, format: AVAudioFormat) -> PlaybackChannel {
        if let existing = channels[channel] { return existing }
        
        let playbackChannel = PlaybackChannel(channel: channel)
        try? playbackChannel.setupNodes(engine: audioEngine!, format: format)
        channels[channel] = playbackChannel
        return playbackChannel
    }

    /// 遅延後に音声再生を開始
    private func startPlaybackAfterDelay(channel: Channel,
                                         playbackChannel: PlaybackChannel,
                                         audioFile: AVAudioFile,
                                         loop: Bool) {
        // エンジン起動（既に起動ならOK）
        if let engine = audioEngine, !engine.isRunning {
            try? engine.start()
        }
        // 再生開始
        playWithCallback(channel: channel, playbackChannel: playbackChannel, file: audioFile)
    }

    /// コールバック付きで音声ファイルを再生
    private func playWithCallback(channel: Channel,
                                  playbackChannel: PlaybackChannel,
                                  file: AVAudioFile,
                                  loop: Bool = false,
                                  completion: (() -> Void)? = nil) {

        playbackChannel.play(file: file, loop: loop) { [weak self] in
            self?.stop(channel)
        }
    }

    /// オーディオファイルをセットアップ
    private func setupAudioFile(named soundName: String, ext: String) throws -> AVAudioFile {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            throw AdvancedSoundPlayerError.audioFileNotFound.nsError
        }
        
        try ensureEngine()
        guard audioEngine != nil else {
            throw AdvancedSoundPlayerError.audioEngineNotFound.nsError
        }
        
        return try AVAudioFile(forReading: url)
    }
}
