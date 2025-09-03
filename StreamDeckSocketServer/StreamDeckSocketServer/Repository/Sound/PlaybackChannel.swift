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
    private var eqNode: AVAudioUnitEQ?
    private var currentFile: AVAudioFile?

    // 各機能のコントローラ
    let rateController: RateController
    let pitchController: PitchController
    let isolatorController: IsolatorController

    // MARK: - Init

    init(channel: AdvancedSoundPlayer.Channel) {
        self.channel = channel
        self.rateController = RateController()
        self.pitchController = PitchController()
        self.isolatorController = IsolatorController()
    }

    // MARK: - Node Management

    /// ノードを作成・設定
    func setupNodes(engine: AVAudioEngine, format: AVAudioFormat) throws {
        // 既存ノードがあれば削除
        cleanupNodes()

        // 新規作成
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitTimePitch()
        let eq = isolatorController.makeEQ()

        // エンジンに接続
        engine.attach(player)
        engine.attach(pitch)
        engine.attach(eq)

        // チェーン接続
        engine.connect(player, to: pitch, format: format)
        engine.connect(pitch, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)

        // 保存
        playerNode = player
        pitchNode = pitch
        eqNode = eq
    }

    /// ノードをクリーンアップ
    private func cleanupNodes() {
        DispatchQueue.main.async {
            self.playerNode?.stop()
        }
        playerNode = nil
        pitchNode = nil
        eqNode = nil
    }

    // MARK: - Playback Control

    /// 音声ファイルを再生
    func play(file: AVAudioFile, loop: Bool = false, completion: (() -> Void)? = nil) {
        guard let player = playerNode else { return }

        currentFile = file

        // 既に再生中なら停止
        if player.isPlaying {
            DispatchQueue.main.async {
                player.stop()
            }
        }

        // スケジュール
        if loop {
            player.scheduleFile(file, at: nil)
        } else {
            player.scheduleFile(file, at: nil) {
                completion?()
            }
        }

        player.play()
    }

    /// 再生停止
    func stop() {
        DispatchQueue.main.async {
            self.playerNode?.stop()
        }
        currentFile = nil
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
}
