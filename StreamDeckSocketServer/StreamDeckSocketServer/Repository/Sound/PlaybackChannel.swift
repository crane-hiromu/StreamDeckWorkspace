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
    private var eqNode: AVAudioUnitEQ?
    private var currentFile: AVAudioFile?
    private var isLoop: Bool = false  // ループ状態を管理
    private var fileDuration: Double = 0.0 // 再生中のファイルの長さ
    private var playbackStartTime: Double = 0.0 // 再生開始時刻

    // 各機能のコントローラ
    let rateController: RateController
    let pitchController: PitchController
    let isolatorController: IsolatorController
    let delayController: DelayController

    // MARK: - Init

    init(channel: AdvancedSoundPlayer.Channel) {
        self.channel = channel
        self.rateController = RateController()
        self.pitchController = PitchController()
        self.isolatorController = IsolatorController()
        self.delayController = DelayController()
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
        let eq = isolatorController.makeEQ()

        // エンジンに接続
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(delay)
        engine.attach(eq)

        // チェーン接続
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: delay, format: format)
        engine.connect(delay, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        // 保存
        playerNode = player
        pitchNode = pitch
        delayNode = delay
        eqNode = eq

        // ディレイを初期状態（無効）に設定
        delayController.reset(on: channel, node: delay)
    }

    /// ノードをクリーンアップ
    private func cleanupNodes() {
        DispatchQueue.main.async {
            self.playerNode?.stop()
        }
        playerNode = nil
        pitchNode = nil
        delayNode = nil
        eqNode = nil
    }

    // MARK: - Playback Control

    /// 音声ファイルを再生
    func play(file: AVAudioFile, loop: Bool = false, completion: (() -> Void)? = nil) {
        guard let player = playerNode else { return }

        currentFile = file
        isLoop = loop

        // 既に再生中なら停止
        if player.isPlaying {
            DispatchQueue.main.async {
                player.stop()
                // 停止完了を待つ（少し遅延）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.playAgain(file: file, completion: completion)
                }
            }
            return
        }
        playAgain(file: file, completion: completion)
    }

    func playAgain(file: AVAudioFile, completion: (() -> Void)? = nil) {
         guard let player = playerNode else { return }
        scheduleFileForPlayback(file: file, completion: completion)
        player.play()
    }

    /// ファイルをスケジュール（ループ対応）
    private func scheduleFileForPlayback(file: AVAudioFile, completion: (() -> Void)?) {
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
                    completion?()
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

    // MARK: - Getters

    var player: AVAudioPlayerNode? { playerNode }
    var pitch: AVAudioUnitTimePitch? { pitchNode }
    var eq: AVAudioUnitEQ? { eqNode }
    var delay: AVAudioUnitDelay? { delayNode }
}
