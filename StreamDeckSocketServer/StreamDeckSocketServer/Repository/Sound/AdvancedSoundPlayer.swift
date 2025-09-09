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
    // Singleton
    static let shared = AdvancedSoundPlayer()
    private init() {}

    // チャンネル
    enum Channel: Int, CaseIterable {
        // トラック用のチャンネル
        case main, sub
        // 効果音用のチャンネル
        case sound
        // ドラム専用チャンネル
        case drum
        // 鍵盤専用チャンネル
        case keyboard
        // 予備のチャンネル
        case other
    }

    // エンジンとチャンネル管理
    private var audioEngine: AVAudioEngine?
    private var channels: [Channel: PlaybackChannel] = [:]
    // トーンコントローラ
    private let toneController = ToneController()

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
            
            // トーンコントローラにオーディオエンジンを設定
            toneController.setAudioEngine(engine)
            
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.startPlaybackAfterDelay(channel: channel, playbackChannel: playbackChannel, audioFile: audioFile, loop: loop)
                }
            } else {
                startPlaybackAfterDelay(channel: channel, playbackChannel: playbackChannel, audioFile: audioFile, loop: loop)
            }
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
    }

    /// 指定されたチャンネルの現在のループ設定を取得
    func isLooping(on channel: Channel) -> Bool {
        guard let playbackChannel = channels[channel] else { return false }
        return playbackChannel.looping
    }

    /// 全チャンネルのループ設定を変更
    func setAllLoops(_ loop: Bool) {
        channels.values.forEach { $0.setLoop(loop) }        
    }

    /// 全チャンネルのループ設定をリセット（false）
    func resetAllLoops() {
        channels.values.forEach { $0.setLoop(false) }
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
    }

    /// 全チャンネルのループ設定を反転
    func toggleAllLoops() {
        channels.values.forEach { channel in
            let newLoopState = !channel.looping
            channel.setLoop(newLoopState)
        }
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

    // 全リセット
    func resetAll() {
        channels.values.forEach { $0.stop() }
        // フロント側の全チャンネルのボリュームも初期値(100)に更新
        resetAllChannelVolumes()
        // フロント側の全チャンネルのリバーブ表示もリセット
        ServerMessageSender.shared.sendReverbResetAllChannels()
        // フロント側の全チャンネルのディレイ表示もリセット
        ServerMessageSender.shared.sendDelayResetAllChannels()
        // フロント側の全チャンネルのフランジャー表示もリセット
        ServerMessageSender.shared.sendFlangerResetAllChannels()
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

    /// ステップ値でディレイのfeedbackを変更
    func changeDelayFeedback(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.changeDelayFeedback(step)
    }

    /// ステップ値でディレイのwetDryMixを変更
    func changeDelayMix(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.changeDelayMix(step)
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

    // MARK: - Flanger Control

    func enableFlanger(on channel: Channel, _ enabled: Bool) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.enableFlanger(enabled)
    }

    func setFlanger(on channel: Channel,
                    delayTime time: Double? = nil,
                    feedback: Float? = nil,
                    wetDryMix mix: Float? = nil) {
        guard let playbackChannel = channels[channel] else { return }
        if let time { playbackChannel.setFlangerDelayTime(time) }
        if let feedback { playbackChannel.setFlangerFeedback(feedback) }
        if let mix { playbackChannel.setFlangerWetDryMix(mix) }
    }

    func resetFlanger(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.resetFlanger()
    }

    func resetAllFlangers() {
        channels.values.forEach { $0.resetFlanger() }
    }

    /// ステップ値でフランジャーのwetDryMixを変更
    func changeFlangerWetDryMix(on channel: Channel, step: Int) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.changeFlangerWetDryMix(step)
    }

    /// k ∈ [-1, 1] でフランジャーをマクロ一括制御
    func setFlangerMacro(on channel: Channel, k: Float) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.setFlangerMacro(k)
    }

    // MARK: - Scratch Control

    /// 指定されたチャンネルでスクラッチ開始（-1.0 〜 1.0の値で制御）
    /// - Parameters:
    ///   - channel: 対象チャンネル
    ///   - value: スクラッチの強度（-1.0: 最大逆再生, 0.0: 停止, 1.0: 最大順再生）
    func startScratch(on channel: Channel, value: Float) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing for channel \(channel)")
            return
        }
        playbackChannel.startScratch(value: value)
    }

    /// 指定されたチャンネルのスクラッチ停止（通常再生に戻す）
    func stopScratching(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.stopScratching()
    }

    /// 指定されたチャンネルのスクラッチ値更新（リアルタイム制御用）
    func updateScratch(on channel: Channel, value: Float) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.updateScratch(value: value)
    }

    /// 指定されたチャンネルでスクラッチの慣性をシミュレート
    func scratchWithInertia(on channel: Channel, value: Float, sensitivity: Float = 1.0) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing for channel \(channel)")
            return
        }
        playbackChannel.scratchWithInertia(value: value, sensitivity: sensitivity)
    }

    /// 指定されたチャンネルでスクラッチのバウンス効果
    func scratchWithBounce(on channel: Channel, value: Float) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing for channel \(channel)")
            return
        }
        playbackChannel.scratchWithBounce(value: value)
    }

    /// 指定されたチャンネルがスクラッチ中かどうか
    func isScratching(on channel: Channel) -> Bool {
        guard let playbackChannel = channels[channel] else { return false }
        return playbackChannel.scratching
    }

    /// 全チャンネルのスクラッチを停止
    func stopAllScratching() {
        channels.values.forEach { $0.stopScratching() }
    }

    // MARK: - Stutter Control

    /// 指定されたチャンネルでストッター開始（指定された秒数分の音をループで流す）
    /// - Parameters:
    ///   - channel: 対象チャンネル
    ///   - segmentLength: ストッターのセグメント長（秒、デフォルト: 0.25）
    func startStutter(on channel: Channel, segmentLength: Double = 0.25) {
        guard let playbackChannel = channels[channel] else { return }
        guard playbackChannel.isPlaying else {
            print("❌ No audio playing for stutter on channel \(channel)")
            return
        }
        playbackChannel.startStutter(segmentLength: segmentLength)
    }

    /// 指定されたチャンネルのストッター停止（通常再生に戻す）
    func stopStutter(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.stopStutter()
    }

    /// 指定されたチャンネルがストッター中かどうか
    func isStuttering(on channel: Channel) -> Bool {
        guard let playbackChannel = channels[channel] else { return false }
        return playbackChannel.stuttering
    }

    /// 指定されたチャンネルのストッターセグメント長を取得
    func stutterSegmentLength(on channel: Channel) -> Double {
        guard let playbackChannel = channels[channel] else { return 0.25 }
        return playbackChannel.stutterSegmentLength
    }

    /// 指定されたチャンネルのストッターセグメント長を変更
    func updateStutterSegmentLength(on channel: Channel, newLength: Double) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.updateStutterSegmentLength(newLength)
    }

    /// 全チャンネルのストッターを停止
    func stopAllStuttering() {
        channels.values.forEach { $0.stopStutter() }
    }
    
    // MARK: - Channel Volume Control
    
    /// 指定されたチャンネルの音量を設定（0.0-1.0）
    func setChannelVolume(_ volume: Float, on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.setChannelVolume(volume)
        
        // サーバーメッセージで音量変更を通知
        ServerMessageSender.shared.sendChannelVolumeChange(
            channel: channel.rawValue,
            volume: Int(volume * 100)
        )
    }
    
    /// 指定されたチャンネルの音量を取得
    func getChannelVolume(on channel: Channel) -> Float {
        guard let playbackChannel = channels[channel] else { return 1.0 }
        return playbackChannel.getChannelVolume()
    }
    
    /// 指定されたチャンネルの音量を調整（相対値）
    func adjustChannelVolume(by delta: Float, on channel: Channel) {
        guard let playbackChannel = channels[channel] else { 
            print("❌ No playback channel found for \(channel)")
            return 
        }
        playbackChannel.adjustChannelVolume(by: delta)
        
        // サーバーメッセージで音量変更を通知
        let newVolume = playbackChannel.getChannelVolume()
        ServerMessageSender.shared.sendChannelVolumeChange(
            channel: channel.rawValue,
            volume: Int(newVolume * 100)
        )
    }
    
    /// 指定されたチャンネルの音量をリセット（1.0）
    func resetChannelVolume(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.resetChannelVolume()
        
        // サーバーメッセージで音量変更を通知
        ServerMessageSender.shared.sendChannelVolumeChange(
            channel: channel.rawValue,
            volume: 0
        )
    }
    
    /// 全チャンネルの音量をリセット（1.0）
    func resetAllChannelVolumes() {
        channels.values.forEach { $0.resetChannelVolume() }
        
        // 全チャンネルの音量変更を通知
        for channel in Channel.allCases {
            ServerMessageSender.shared.sendChannelVolumeChange(
                channel: channel.rawValue,
                volume: 100
            )
        }
    }
    
    /// 指定されたチャンネルの音量をミュート/アンミュート
    func toggleChannelMute(on channel: Channel) {
        guard let playbackChannel = channels[channel] else { return }
        playbackChannel.toggleChannelMute()
        
        // サーバーメッセージで音量変更を通知
        let newVolume = playbackChannel.getChannelVolume()
        ServerMessageSender.shared.sendChannelVolumeChange(
            channel: channel.rawValue,
            volume: Int(newVolume * 100)
        )
    }

    // MARK: - Tone Generation
    
    /// 指定された音階を指定されたチャンネルで再生（低遅延）
    func playTone(_ note: String, on channel: Channel) {
        do {
            try toneController.playTone(note)
        } catch {
            print("❌ Failed to play tone \(note): \(error)")
        }
    }
    
    /// 利用可能な音階のリストを取得
    var availableTones: [String] {
        return toneController.availableTones
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
        if let existing = channels[channel] { 
            print("🔊 [Channel \(channel.rawValue+1)] Using existing playback channel")
            return existing 
        }
        
        print("🔊 [Channel \(channel.rawValue+1)] Creating new playback channel")
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
