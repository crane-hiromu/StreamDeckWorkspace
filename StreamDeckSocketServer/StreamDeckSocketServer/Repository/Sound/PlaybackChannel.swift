//
//  PlaybackChannel.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/09/03.
//

import Foundation
import AVFoundation

/// 単一チャンネルの再生状態を管理するクラス
/// - PlayerNode、PitchNode、EQNode、ファイル、コントローラを統合管理
final class PlaybackChannel {

    // MARK: - Properties

    let channel: AdvancedSoundPlayer.Channel
    private var playerNode: AVAudioPlayerNode?
    private var pitchNode: AVAudioUnitTimePitch?
    private var delayNode: AVAudioUnitDelay?
    private var reverbNode: AVAudioUnitReverb?
    private var flangerNode: AVAudioUnitDelay?
    private var eqNode: AVAudioUnitEQ?
    private var currentFile: AVAudioFile?
    private var isLoop: Bool = false  // ループ状態を管理
    private var fileDuration: Double = 0.0 // 再生中のファイルの長さ
    private var playbackStartTime: Double = 0.0 // 再生開始時刻
    private var currentCompletionId: Int = 0 // 現在の完了コールバックのID
    private var completionCounter: Int = 0 // 完了コールバックのカウンター
    
    // チャンネル固有の音量制御
    private var channelVolume: Float = 1.0 // チャンネル音量（0.0-1.0）
    private var previousChannelVolume: Float? = nil // ミュート前の音量を記憶
    private var volumeNode: AVAudioUnitEQ? // 音量制御用のEQノード

    // 各機能のコントローラ
    let rateController: RateController
    let pitchController: PitchController
    let isolatorController: IsolatorController
    let delayController: DelayController
    let reverbController: ReverbController
    let flangerController: FlangerController
    let scratchController: ScratchController
    let stutterController: StutterController

    // MARK: - Init

    init(channel: AdvancedSoundPlayer.Channel) {
        self.channel = channel
        self.rateController = RateController()
        self.pitchController = PitchController()
        self.isolatorController = IsolatorController()
        self.delayController = DelayController()
        self.reverbController = ReverbController()
        self.flangerController = FlangerController()
        self.scratchController = ScratchController()
        self.stutterController = StutterController()
    }

    // MARK: - Node Management

    /// ノードを作成・設定
    func setupNodes(engine: AVAudioEngine, format: AVAudioFormat) throws {
        // 既存ノードがあれば削除
        cleanupNodes()

        // 新規作成
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        let delay = AVAudioUnitDelay()
        let reverb = AVAudioUnitReverb()
        let flanger = AVAudioUnitDelay()
        let eq = isolatorController.makeEQ()
        let volume = AVAudioUnitEQ(numberOfBands: 1) // 音量制御用のEQノード

        // エンジンに接続
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(delay)
        engine.attach(reverb)
        engine.attach(flanger)
        engine.attach(eq)
        engine.attach(volume)

        // チェーン接続
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: delay, format: format)
        engine.connect(delay, to: reverb, format: format)
        engine.connect(reverb, to: flanger, format: format)
        engine.connect(flanger, to: eq, format: format)
        engine.connect(eq, to: volume, format: format)
        engine.connect(volume, to: engine.mainMixerNode, format: format)

        // 保存
        playerNode = player
        pitchNode = pitch
        delayNode = delay
        reverbNode = reverb
        flangerNode = flanger
        eqNode = eq
        volumeNode = volume
        
        // 音量制御用EQノードの設定
        setupVolumeNode()
        
        // 初期音量を設定（1.0 = 100%）
        setChannelVolume(1.0)

        // ディレイを初期状態（無効）に設定
        delayController.reset(on: channel, node: delay)
        // リバーブを初期状態（無効）に設定
        reverbController.reset(on: channel, node: reverb)
        // フランジャーを初期状態（無効）に設定
        flangerController.reset(on: channel, node: flanger)
    }

    /// ノードをクリーンアップ
    private func cleanupNodes() {
        DispatchQueue.main.async {
            self.playerNode?.stop()
        }
        playerNode = nil
        pitchNode = nil
        delayNode = nil
        reverbNode = nil
        flangerNode = nil
        eqNode = nil
        volumeNode = nil
    }

    // MARK: - Playback Control

    /// 音声ファイルを再生
    func play(file: AVAudioFile, loop: Bool = false, completion: (() -> Void)? = nil) {
        guard let player = playerNode else { return }

        // 新しい再生時は古い完了コールバックを無効化
        completionCounter += 1
        currentCompletionId = completionCounter
        currentFile = file
        isLoop = loop

        // 既に再生中なら停止
        if player.isPlaying {
            DispatchQueue.main.async {
                player.stop()
                // 停止完了を待つ（連打対応で短縮）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.playAgain(file: file, completion: completion)
                }
            }
            return
        }
        playAgain(file: file, completion: completion)
    }

    func playAgain(file: AVAudioFile, completion: (() -> Void)? = nil) {
         guard let player = playerNode else { return }
        scheduleFileForPlayback(file: file, completion: completion, completionId: currentCompletionId)
        
        // 再生開始時刻を記録
        playbackStartTime = Date().timeIntervalSince1970
        
        // 再生開始前に音量を確認・設定
        player.volume = channelVolume
        player.play()
    }

    /// ファイルをスケジュール（ループ対応）
    private func scheduleFileForPlayback(file: AVAudioFile, completion: (() -> Void)?, completionId: Int) {
        guard let player = playerNode else { return }
        
        player.scheduleFile(file, at: nil) { [weak self] in
            // ループ再生の場合、再度スケジュール
            if self?.isLoop == true {
                DispatchQueue.main.async {
                    self?.playAgain(file: file, completion: completion)
                }
            // 通常再生の場合、再生完了したファイルが同じかチェック（これがないと連打できない）
            } else if self?.currentFile === file {
                // 完了コールバックを実行。
                // 終了の検知が少し早いため最後の音がカットされないように終了を遅らせる。
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // 現在の完了コールバックIDと一致する場合のみ実行（連打対応）
                    if self?.currentCompletionId == completionId {
                        completion?()
                    }
                }
            }
        }
    }

    /// ループ状態を切り替え
    func setLoop(_ enabled: Bool) {
        isLoop = enabled
    }

    /// ループ状態を取得
    var looping: Bool {
        return isLoop
    }

    /// 再生停止
    func stop() {
        DispatchQueue.main.async {
            self.playerNode?.stop()
        }
        currentFile = nil
        isLoop = false
        rateController.reset()
        pitchController.reset()
        stutterController.reset()
        setPitch(0.0)
        resetIsolator()
        resetReverb()
        resetFlanger()
        resetDelay()
        stopScratching()
        stopStutter()
        resetChannelVolume()
    }

    /// 再生中かどうか
    var isPlaying: Bool {
        playerNode?.isPlaying ?? false
    }

    // MARK: - Volume Control
    
    /// 音量制御用EQノードの設定
    private func setupVolumeNode() {
        guard let volume = volumeNode else { 
            print("❌ [Channel \(channel.rawValue+1)] Volume node is nil in setupVolumeNode")
            return 
        }
        
        // 音量制御用のEQバンドを設定（全周波数帯域でゲイン調整）
        let band = volume.bands[0]
        band.filterType = .lowShelf // より広い周波数帯域をカバー
        band.frequency = 80.0 // 低周波数で設定
        band.gain = 0.0 // 初期値は0dB
        band.bypass = false
    }
    
    /// チャンネル音量を設定（0.0-1.0）
    func setChannelVolume(_ volume: Float) {
        let clampedVolume = min(max(volume, 0.0), 1.0)
        channelVolume = clampedVolume
        
        // 方法1: AVAudioPlayerNodeのvolumeプロパティを使用
        if let player = playerNode {
            player.volume = clampedVolume
        } else {
            print("❌ [Channel \(channel.rawValue+1)] PlayerNode is nil!")
        }
        
        // 方法2: EQノードのゲインも設定（バックアップ）
        if let volumeNode = volumeNode {
            let gainInDB = clampedVolume > 0.0 ? 20.0 * log10(clampedVolume) : -96.0
            volumeNode.bands[0].gain = gainInDB
        }
    }
    
    /// チャンネル音量を取得
    func getChannelVolume() -> Float {
        return channelVolume
    }
    
    /// チャンネル音量を調整（相対値）
    func adjustChannelVolume(by delta: Float) {
        let newVolume = min(max(channelVolume + delta, 0.0), 1.0)
        setChannelVolume(newVolume)
    }
    
    /// チャンネル音量をリセット（1.0）
    func resetChannelVolume() {
        setChannelVolume(1.0)
        previousChannelVolume = nil // 前回の音量もクリア
    }
    
    /// チャンネル音量をミュート/アンミュート
    func toggleChannelMute() {
        if channelVolume > 0 {
            // ミュートする前に音量を保存
            previousChannelVolume = channelVolume
            setChannelVolume(0.0)
        } else if let prev = previousChannelVolume {
            // 前の音量に戻す
            setChannelVolume(prev)
            previousChannelVolume = nil
        } else {
            // 前の音量がない場合は1.0に設定
            setChannelVolume(1.0)
        }
    }

    // MARK: - Effect Control

    /// レート変更
    func setRate(_ rate: Float) {
        pitchNode?.rate = rate
        rateController.setRate(rate)
    }

    /// ピッチ変更
    func setPitch(_ cents: Float) {
        let clamped = min(max(cents, -2400), 2400)
        pitchNode?.pitch = clamped
        pitchController.setCents(clamped)
    }

    // MARK: - Delay Control

    func enableDelay(_ enabled: Bool) {
        guard let delay = delayNode else { return }
        delayController.setEnabled(enabled, on: channel, node: delay)
    }

    func setDelayTime(_ seconds: Float) {
        guard let delay = delayNode else { return }
        delayController.set(time: seconds, on: channel, node: delay)
    }

    func setDelayFeedback(_ percent: Float) {
        guard let delay = delayNode else { return }
        delayController.set(feedback: percent, on: channel, node: delay)
    }

    func setDelayMix(_ percent: Float) {
        guard let delay = delayNode else { return }
        delayController.set(wetDryMix: percent, on: channel, node: delay)
    }

    func resetDelay() {
        guard let delay = delayNode else { return }
        delayController.reset(on: channel, node: delay)
    }

    /// k ∈ [-1, 1] でマクロ一括制御（time/feedback/mix 同時）
    func setDelayMacro(_ k: Float) {
        guard let delay = delayNode else { return }
        delayController.setMacro(k: k, on: channel, node: delay)
    }

    /// ステップ値でディレイのfeedbackを変更
    func changeDelayFeedback(_ step: Int) {
        guard let delay = delayNode else { return }
        delayController.changeFeedback(step: step, on: channel, node: delay)
    }

    /// ステップ値でディレイのwetDryMixを変更
    func changeDelayMix(_ step: Int) {
        guard let delay = delayNode else { return }
        delayController.changeMix(step: step, on: channel, node: delay)
    }

    // MARK: - Reverb Control

    func enableReverb(_ enabled: Bool) {
        guard let reverb = reverbNode else { return }
        reverbController.setEnabled(enabled, on: channel, node: reverb)
    }

    func setReverbMix(_ percent: Float) {
        guard let reverb = reverbNode else { return }
        reverbController.set(wetDryMix: percent, on: channel, node: reverb)
    }

    func resetReverb() {
        guard let reverb = reverbNode else { return }
        reverbController.reset(on: channel, node: reverb)
    }

    /// k ∈ [-1, 1] でマクロ一括制御（wetDryMix のみ）
    func setReverbMacro(_ k: Float) {
        guard let reverb = reverbNode else { return }
        reverbController.setMacro(k: k, on: channel, node: reverb)
    }

    // MARK: - Flanger Control

    func enableFlanger(_ enabled: Bool) {
        guard let flanger = flangerNode else { return }
        flangerController.setEnabled(enabled, on: channel, node: flanger)
    }

    func setFlangerDelayTime(_ time: Double) {
        guard let flanger = flangerNode else { return }
        flangerController.set(delayTime: time, on: channel, node: flanger)
    }

    func setFlangerFeedback(_ feedback: Float) {
        guard let flanger = flangerNode else { return }
        flangerController.set(feedback: feedback, on: channel, node: flanger)
    }

    func setFlangerWetDryMix(_ mix: Float) {
        guard let flanger = flangerNode else { return }
        flangerController.set(wetDryMix: mix, on: channel, node: flanger)
    }

    func resetFlanger() {
        guard let flanger = flangerNode else { return }
        flangerController.reset(on: channel, node: flanger)
    }

    /// ステップ値でフランジャーのwetDryMixを変更
    func changeFlangerWetDryMix(_ step: Int) {
        guard let flanger = flangerNode else { return }
        flangerController.changeWetDryMix(step: step, on: channel, node: flanger)
    }

    /// k ∈ [-1, 1] でマクロ一括制御（delayTime/feedback/wetDryMix 同時）
    func setFlangerMacro(_ k: Float) {
        guard let flanger = flangerNode else { return }
        flangerController.setMacro(k: k, on: channel, node: flanger)
    }

    /// ステップ値でリバーブのwetDryMixを変更
    func changeReverbWetDryMix(_ step: Int) {
        guard let reverb = reverbNode else { return }
        reverbController.changeWetDryMix(step: step, on: channel, node: reverb)
    }

    // MARK: - Isolator Control

    /// ノブ値（トグルの累積）を -1...1 に正規化して、LOW/MID/HIGH のゲインを更新
    func updateIsolatorBalance(step: Int, sensitivity: Float = 1.0/20.0) {
        guard let eq = eqNode else { return }
        isolatorController.updateBalance(on: channel, eq: eq, step: step, sensitivity: sensitivity)
    }

    /// アイソレーター状態を直接設定（スムージング対応）
    func setIsolatorBalance(value s: Float, smoothing: Float = 0.15) {
        guard let eq = eqNode else { return }
        isolatorController.setBalance(on: channel, eq: eq, value: s, smoothing: smoothing)
    }

    /// アイソレーターをリセット（フラット）
    func resetIsolator() {
        guard let eq = eqNode else { return }
        isolatorController.reset(on: channel, eq: eq)
    }

    // MARK: - Scratch Control
    
    /// スクラッチ開始（-1.0 〜 1.0の値で制御）
    /// - Parameter value: スクラッチの強度（-1.0: 最大逆再生, 0.0: 停止, 1.0: 最大順再生）
    func startScratch(value: Float) {
        guard let pitch = pitchNode else { return }
        scratchController.startScratch(value: value, pitchNode: pitch, channel: channel)
    }
    
    /// スクラッチ停止（通常再生に戻す）
    func stopScratching() {
        guard let pitch = pitchNode else { return }
        scratchController.stopScratching(pitchNode: pitch, channel: channel)
    }
    
    /// スクラッチ値の更新（リアルタイム制御用）
    func updateScratch(value: Float) {
        guard let pitch = pitchNode else { return }
        scratchController.updateScratch(value: value, pitchNode: pitch, channel: channel)
    }
    
    /// スクラッチの慣性をシミュレート（より自然なスクラッチ感）
    func scratchWithInertia(value: Float, sensitivity: Float = 1.0) {
        guard let pitch = pitchNode else { return }
        scratchController.scratchWithInertia(value: value, sensitivity: sensitivity, pitchNode: pitch, channel: channel)
    }
    
    /// スクラッチのバウンス効果
    func scratchWithBounce(value: Float) {
        guard let pitch = pitchNode else { return }
        scratchController.scratchWithBounce(value: value, pitchNode: pitch, channel: channel)
    }
    
    /// スクラッチ中かどうか
    var scratching: Bool {
        return scratchController.scratching
    }
    
    // MARK: - Stutter Control
    
    /// ストッター開始（指定された秒数分の音をループで流す）
    /// - Parameter segmentLength: ストッターのセグメント長（秒）
    func startStutter(segmentLength: Double = 0.25) {
        guard let player = playerNode, let file = currentFile else { return }
        guard isPlaying else {
            print("❌ No audio playing for stutter on channel \(channel)")
            return
        }
        
        // ストッター中なら停止、そうでなければ開始
        if stutterController.stuttering {
            stopStutter()
        } else {
            // ループ再生中でも即座にストッターを開始
            // 現在の再生位置を簡易計算（ループ対応）
            let currentTime = getCurrentPlaybackTimeForLoop(file: file)
            
            // ストッター開始時のループ状態を記録
            stutterController.setStutterStartLoop(isLoop)
            
            stutterController.startStutter(
                segmentLength: segmentLength,
                playerNode: player,
                channel: channel,
                currentTime: currentTime,
                audioFile: file
            )
        }
    }
    
    /// 現在の再生位置を取得
    private func getCurrentPlaybackTime() -> Double {
        guard playerNode != nil else { return 0.0 }
        
        // より実用的な方法で現在の再生位置を取得
        // 再生開始からの経過時間を簡易計算
        let currentTime = Date().timeIntervalSince1970
        let playbackStartTime = playbackStartTime
        
        // 再生開始からの経過時間を返す（簡易版）
        return max(0.0, currentTime - playbackStartTime)
    }
    
    /// ループ対応の現在の再生位置を取得
    private func getCurrentPlaybackTimeForLoop(file: AVAudioFile) -> Double {
        guard playerNode != nil else { return 0.0 }
        
        // 再生開始からの経過時間を計算
        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = currentTime - playbackStartTime
        
        // ファイルの長さを取得
        let fileDuration = Double(file.length) / file.fileFormat.sampleRate
        
        // ループ再生の場合、ファイル長で割った余りを返す
        if isLoop && fileDuration > 0 {
            return elapsedTime.truncatingRemainder(dividingBy: fileDuration)
        }
        
        // 通常再生の場合は経過時間をそのまま返す
        return max(0.0, elapsedTime)
    }
    
    /// ストッター停止（通常再生に戻す）
    func stopStutter() {
        guard let player = playerNode, let file = currentFile else { return }
        stutterController.stopStutter(playerNode: player, channel: channel)
        
        // ストッター開始時の位置から通常再生を再開
        let stutterStartTime = stutterController.getStutterStartTime()
        let stutterStartLoop = stutterController.getStutterStartLoop()
        
        // ストッター開始時のループ状態に戻す
        isLoop = stutterStartLoop
        
        // ストッター開始時の位置から再生を再開
        if stutterStartLoop {
            // ループ再生を再開（ストッター開始時の位置から）
            resumeFromPosition(file: file, startTime: stutterStartTime, loop: true)
        } else {
            // 通常再生を再開（ストッター開始時の位置から）
            resumeFromPosition(file: file, startTime: stutterStartTime, loop: false)
        }
    }
    
    /// ストッター中かどうか
    var stuttering: Bool {
        return stutterController.stuttering
    }
    
    /// ストッターのセグメント長を取得
    var stutterSegmentLength: Double {
        return stutterController.currentSegmentLength
    }
    
    /// ストッターのセグメント長を変更
    func updateStutterSegmentLength(_ newLength: Double) {
        stutterController.updateSegmentLength(newLength)
    }
    
    /// 指定された位置から再生を再開
    private func resumeFromPosition(file: AVAudioFile, startTime: Double, loop: Bool) {
        guard let player = playerNode else { return }
        
        // 新しい再生時は古い完了コールバックを無効化
        completionCounter += 1
        currentCompletionId = completionCounter
        currentFile = file
        isLoop = loop
        
        // 再生開始時刻を記録（ストッター開始時の位置を考慮）
        playbackStartTime = Date().timeIntervalSince1970 - startTime
        
        // ファイルをスケジュール（特定位置から再生）
        scheduleFileFromPosition(file: file, startTime: startTime, completion: nil, completionId: currentCompletionId)
        
        // 再生開始
        player.play()
    }
    
    /// ファイルを特定位置からスケジュール（ループ対応）
    private func scheduleFileFromPosition(file: AVAudioFile, startTime: Double, completion: (() -> Void)?, completionId: Int) {
        guard let player = playerNode else { return }
        
        // ファイルの長さを取得
        let fileDuration = Double(file.length) / file.fileFormat.sampleRate
        
        // ループ再生の場合、ファイル長で割った余りを使用
        let actualStartTime = startTime.truncatingRemainder(dividingBy: fileDuration)
        
        // 残りの長さを計算
        let remainingDuration = fileDuration - actualStartTime
        
        // 残りの部分をバッファとして読み込み
        let format = file.processingFormat
        let remainingFrames = UInt32(remainingDuration * format.sampleRate)
        
        if remainingFrames > 0 {
            // 残りの部分をバッファとして作成
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: remainingFrames) else {
                print("❌ Failed to create resume buffer")
                return
            }
            
            do {
                // 指定位置から残りの部分を読み込み
                file.framePosition = AVAudioFramePosition(actualStartTime * format.sampleRate)
                try file.read(into: buffer, frameCount: remainingFrames)
                
                // バッファをスケジュール
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
                    // ループ再生の場合、再度スケジュール
                    if self?.isLoop == true {
                        DispatchQueue.main.async {
                            self?.playAgain(file: file, completion: completion)
                        }
                    // 通常再生の場合、再生完了したファイルが同じかチェック
                    } else if self?.currentFile === file {
                        // 完了コールバックを実行
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // 現在の完了コールバックIDと一致する場合のみ実行
                            if self?.currentCompletionId == completionId {
                                completion?()
                            }
                        }
                    }
                })
                
            } catch {
                print("❌ Failed to read resume buffer: \(error)")
            }
        } else {
            // 残り時間がない場合、ループ再生なら最初から
            if isLoop {
                playAgain(file: file, completion: completion)
            }
        }
    }

    // MARK: - Getters

    var player: AVAudioPlayerNode? { playerNode }
    var pitch: AVAudioUnitTimePitch? { pitchNode }
    var eq: AVAudioUnitEQ? { eqNode }
    var delay: AVAudioUnitDelay? { delayNode }
    var reverb: AVAudioUnitReverb? { reverbNode }
    var flanger: AVAudioUnitDelay? { flangerNode }
    var volume: AVAudioUnitEQ? { volumeNode }
}
