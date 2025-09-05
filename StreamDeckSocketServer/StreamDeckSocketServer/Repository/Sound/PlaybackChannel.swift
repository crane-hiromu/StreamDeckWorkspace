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

    // 各機能のコントローラ
    let rateController: RateController
    let pitchController: PitchController
    let isolatorController: IsolatorController
    let delayController: DelayController
    let reverbController: ReverbController
    let flangerController: FlangerController
    let scratchController: ScratchController

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

        // エンジンに接続
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(delay)
        engine.attach(reverb)
        engine.attach(flanger)
        engine.attach(eq)

        // チェーン接続
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: delay, format: format)
        engine.connect(delay, to: reverb, format: format)
        engine.connect(reverb, to: flanger, format: format)
        engine.connect(flanger, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        // 保存
        playerNode = player
        pitchNode = pitch
        delayNode = delay
        reverbNode = reverb
        flangerNode = flanger
        eqNode = eq

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
        setPitch(0.0)
        stopScratching()
    }

    /// 再生中かどうか
    var isPlaying: Bool {
        playerNode?.isPlaying ?? false
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
    

    // MARK: - Getters

    var player: AVAudioPlayerNode? { playerNode }
    var pitch: AVAudioUnitTimePitch? { pitchNode }
    var eq: AVAudioUnitEQ? { eqNode }
    var delay: AVAudioUnitDelay? { delayNode }
    var reverb: AVAudioUnitReverb? { reverbNode }
    var flanger: AVAudioUnitDelay? { flangerNode }
}
