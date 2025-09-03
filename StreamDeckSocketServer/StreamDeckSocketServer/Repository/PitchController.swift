//
//  PitchController.swift
//  StreamDeckSocketServer
//
//  Created by Assistant on 2025/09/03.
//

import Foundation

/// ピッチ（セント）を段階的に制御するコントローラ
/// - セント単位で累積し、範囲をクランプ
final class PitchController {

    // MARK: Tunables

    /// ピッチ最小値（セント）
    private let minCents: Float
    /// ピッチ最大値（セント）
    private let maxCents: Float
    /// ステップ感度（1ステップあたりのセント換算、既定: 100c）
    private let centsPerUnit: Float
    /// 入力ステップの減衰（小さいほど1回の変化が小さい、既定: 1/5）
    private let stepSensitivity: Float

    // MARK: State
    private var cumulativeCents: Float = 0

    // MARK: Init
    init(
        minCents: Float = -2400,
        maxCents: Float = 2400,
        centsPerUnit: Float = 100,
        stepSensitivity: Float = 1.0 / 5.0
    ) {
        self.minCents = minCents
        self.maxCents = maxCents
        self.centsPerUnit = centsPerUnit
        self.stepSensitivity = stepSensitivity
    }

    // MARK: Public
    /// ステップ入力からピッチを変更し、現在のピッチ（セント）を返します
    @discardableResult
    func change(step: Int) -> Float {
        let clamped = Float(Swift.max(Swift.min(step, 8), -8))
        guard clamped != 0 else { return currentCents }
        let delta = clamped * stepSensitivity * centsPerUnit
        cumulativeCents = Swift.max(Swift.min(cumulativeCents + delta, maxCents), minCents)
        return currentCents
    }

    /// ピッチ（セント）を直接設定
    func setCents(_ cents: Float) {
        cumulativeCents = Swift.max(Swift.min(cents, maxCents), minCents)
    }

    /// リセット（0セント）
    func reset() { cumulativeCents = 0 }

    /// 現在のピッチ（セント）
    var currentCents: Float { cumulativeCents }
}


