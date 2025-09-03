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
    private var eqNodes: [Channel: AVAudioUnitEQ] = [:]
    private var currentFiles: [Channel: AVAudioFile] = [:]
    // レート制御（等比）をチャンネルごとに管理
    private var rateControllers: [Channel: RateController] = [:]
    private var cumulativePitchCents: [Channel: Float] = [:]
    private var isolatorBalance: [Channel: Float] = [:] // -1.0 (LOW boost) ... 0 ... +1.0 (HIGH boost)
    
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
            setupRate(nodes: (nodes.player, nodes.pitch), channel: channel, rate: rate)
            // 既存再生の処理
            if handleExistingPlayback(nodes: (nodes.player, nodes.pitch), audioFile: audioFile, channel: channel, loop: loop) {
                return 
            }
            // 初回再生の開始
            startPlayback(nodes: (nodes.player, nodes.pitch), audioFile: audioFile, channel: channel, loop: loop)
            
            print("🎵 [Channel \(channel.rawValue+1)] Playing \(soundName) rate=\(rate) loop=\(loop)")
            
        } catch {
            print("❌ Failed to play on channel \(channel): \(error)")
        }
    }
        
    // ステップ値から再生レートを算出（等比スケール）
    static func rate(for step: Int) -> Float {
        RateController.rate(for: step, base: Self.rateBase, lowerBound: Self.rateMin, upperBound: Self.rateMax)
    }
    
    // ステップ指定でレート変更
    func changeRate(on channel: Channel, step: Int) {
        let controller = ensureRateController(for: channel)
        let newRate = controller.change(step: step)
        setRate(on: channel, rate: newRate)
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
        // RateControllerへも同期
        ensureRateController(for: channel).setRate(rate)
        print("🎵 [Channel \(channel.rawValue+1)] rate -> \(rate)")
    }

    // ステップ指定でピッチ変更
    func changePitch(on channel: Channel, step: Int) {
        let rawDelta = max(min(step, 8), -8)
        guard rawDelta != 0 else { return }

        // 感度を1/5に減衰し、セント換算（1.0 -> 100 cents として扱う）
        let attenuated = Float(rawDelta) / 5.0
        let deltaCents = attenuated * 100.0

        let current = cumulativePitchCents[channel] ?? 0
        let updated = max(min(current + deltaCents, 2400.0), -2400.0)
        cumulativePitchCents[channel] = updated

        setPitch(on: channel, pitch: updated)
    }
    // 指定されたチャンネルのピッチを変更
    func setPitch(on channel: Channel, pitch: Float) {
        guard let pitchNode = pitchNodes[channel],
              let player = playerNodes[channel],
              player.isPlaying else {
            print("❌ No audio playing or components not available for channel \(channel)")
            return
        }
        
        // ピッチ値を-2400〜2400の範囲に制限
        let clampedPitch = min(max(pitch, -2400), 2400)
        pitchNode.pitch = clampedPitch
        
        print("🎵 [Channel \(channel.rawValue+1)] pitch -> \(clampedPitch) cents")
    }

    // レートをデフォルト(1.0)に戻す（指定チャンネル）
    func resetRate(on channel: Channel) {
        ensureRateController(for: channel).reset()
        setRate(on: channel, rate: 1.0)
    }

    // 指定されたチャンネルのピッチをデフォルト（0セント）に戻します
    func resetPitch(on channel: Channel) {
        setPitch(on: channel, pitch: 0.0)
        cumulativePitchCents[channel] = 0
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
        rateControllers[channel]?.reset()
    }

    // 全停止
    func stopAll() {
        playerNodes.values.forEach { $0.stop() }
        currentFiles.removeAll()
        rateControllers.values.forEach { $0.reset() }
    }

    // 全チャンネルのレートをデフォルトに戻す
    func resetAllRates() {
        Channel.allCases.forEach { ch in
            resetRate(on: ch)
        }
    }

    // 全チャンネルのピッチをデフォルトに戻す
    func resetAllPitch() {
        Channel.allCases.forEach { ch in
            resetPitch(on: ch)
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
    ) throws -> (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch, eq: AVAudioUnitEQ) {

        if let player = playerNodes[channel], let pitch = pitchNodes[channel], let eq = eqNodes[channel] {
            return (player, pitch, eq)
        }
        guard let engine = audioEngine else {
            throw AdvancedSoundPlayerError.audioEngineNotFound.nsError
        }

        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        let eq = makeIsolatorEQ()
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(eq)

        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        playerNodes[channel] = player
        pitchNodes[channel] = pitch
        eqNodes[channel] = eq
        if rateControllers[channel] == nil { rateControllers[channel] = RateController() }
        return (player, pitch, eq)
    }

    private func ensureRateController(for channel: Channel) -> RateController {
        if let rc = rateControllers[channel] { return rc }
        let rc = RateController()
        rateControllers[channel] = rc
        return rc
    }

    // Isolator EQ Factory
    private func makeIsolatorEQ() -> AVAudioUnitEQ {
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

    // MARK: Isolator (1-knob)

    /// ノブ値（トグルの累積）を -1...1 に正規化して、LOW/MID/HIGH のゲインを更新
    /// s < 0: 低音ブースト / s > 0: 高音ブースト / s ≈ 0: フラット
    func updateIsolatorBalance(on channel: Channel, step: Int, sensitivity: Float = 1.0/20.0) {
        // 累積
        let delta = Float(step) * sensitivity
        let current = isolatorBalance[channel] ?? 0
        let clamped = max(min(current + delta, 1.0), -1.0)
        isolatorBalance[channel] = clamped

        applyIsolator(on: channel, state: clamped)
    }

    /// アイソレーター状態を直接設定（スムージング対応）
    /// - Parameters:
    ///   - channel: 対象チャンネル
    ///   - value: 設定するターゲット値（-1.0...1.0）
    ///   - smoothing: スムージング係数（0.0...1.0）小さいほど1回の変化量が小さい。既定: 0.25
    func setIsolatorBalance(on channel: Channel, value s: Float, smoothing: Float = 0.15) {
        let clamped = max(min(s, 1.0), -1.0)
        let current = isolatorBalance[channel] ?? 0
        let k = max(0.0, min(smoothing, 1.0))
        let blended = current + (clamped - current) * k
        isolatorBalance[channel] = blended
        applyIsolator(on: channel, state: blended)
    }

    /// 内部: バランス値から各バンドのゲインを決定して適用
    private func applyIsolator(on channel: Channel, state s: Float) {
        guard let eq = eqNodes[channel] else { return }
        guard eq.bands.count >= 3 else { return }

        // マッピング関数
        func boost(_ x: Float) -> Float { return 24.0 * powf(x, 1.6) }   // dB
        func cut(_ x: Float)   -> Float { return -60.0 * powf(x, 1.2) }  // dB (負値)

        let pos = max(0,  s)   // 高音側（右）
        let neg = max(0, -s)   // 低音側（左）
        // 反対側も比例カットする対称マッピング
        let lowGain  = neg > 0 ? boost(neg) : cut(pos)
        let highGain = pos > 0 ? boost(pos) : cut(neg)
        let midGain  = cut(abs(s))

        // 適用
        eq.bands[0].gain = lowGain
        eq.bands[1].gain = midGain
        eq.bands[2].gain = highGain
    }

    /// 指定チャンネルのアイソレーターをリセット（フラット）
    func resetIsolator(on channel: Channel) {
        isolatorBalance[channel] = 0
        guard let eq = eqNodes[channel] else { return }
        guard eq.bands.count >= 3 else { return }
        eq.bands[0].gain = 0
        eq.bands[1].gain = 0
        eq.bands[2].gain = 0
    }

    /// 全チャンネルのアイソレーターをリセット（フラット）
    func resetAllIsolators() {
        Channel.allCases.forEach { resetIsolator(on: $0) }
    }

    /**
     * オーディオファイルをセットアップします
     */
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
    
    /**
     * レート設定を行います
     */
    private func setupRate(
        nodes: (player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch),
        channel: Channel,
        rate: Float
    ) {
        nodes.pitch.rate = rate
        ensureRateController(for: channel).setRate(rate)
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
