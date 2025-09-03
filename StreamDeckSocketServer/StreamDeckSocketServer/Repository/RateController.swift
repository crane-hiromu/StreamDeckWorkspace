//
//  RateController.swift
//  StreamDeckSocketServer
//
//  Created by Assistant on 2025/09/03.
//

import Foundation

/// 再生レートを段階的に制御するコントローラ
/// - 等比スケール（base^step）でレートを算出
/// - ステップ入力（ダイヤルの回転）を減衰させて累積・可逆に調整
final class RateController {

    // MARK: Tunables

    /// 最小レート
    private let rateMin: Float
    /// 最大レート
    private let rateMax: Float
    /// 等比の底（> 1.0）
    private let rateBase: Float
    /// ステップ感度（小さいほど1回の変化が小さい）
    private let stepSensitivity: Float
    /// 累積ステップのクランプ幅（絶対値）
    private let cumulativeClamp: Float

    // MARK: State

    /// 累積ステップ（実数）
    private var cumulativeStep: Float = 0

    // MARK: Init

    /// - Parameters:
    ///   - rateMin: 最小レート（既定: 0.5）
    ///   - rateMax: 最大レート（既定: 3.0）
    ///   - rateBase: 等比の底（既定: 1.2）
    ///   - stepSensitivity: ステップ感度（既定: 0.1 → 1/10）
    ///   - cumulativeClamp: 累積クランプ絶対値（既定: 24.0）
    init(
        rateMin: Float = 0.5,
        rateMax: Float = 3.0,
        rateBase: Float = 1.2,
        stepSensitivity: Float = 0.1,
        cumulativeClamp: Float = 24.0
    ) {
        self.rateMin = rateMin
        self.rateMax = rateMax
        self.rateBase = rateBase
        self.stepSensitivity = stepSensitivity
        self.cumulativeClamp = cumulativeClamp
    }

    // MARK: Public

    /// ステップ入力からレートを変更し、現在のレートを返します
    /// - Parameter step: 入力ステップ（-∞〜+∞の想定、内部で -8〜+8 にクランプ）
    /// - Returns: 変更後のレート
    @discardableResult
    func change(step: Int) -> Float {
        let clampedStep = Float(max(min(step, 8), -8))
        guard clampedStep != 0 else { return currentRate }

        // 感度を減衰して累積（可逆）
        cumulativeStep = max(
            min(cumulativeStep + clampedStep * stepSensitivity, cumulativeClamp),
            -cumulativeClamp
        )
        return currentRate
    }

    /// レートを直接設定し、内部の累積ステップも同期します
    /// - Parameter rate: 設定するレート
    func setRate(_ rate: Float) {
        let clamped = min(max(rate, rateMin), rateMax)
        // base^x = clamped → x = log(clamped)/log(base)
        if clamped > 0, rateBase > 0 {
            cumulativeStep = logf(clamped) / logf(rateBase)
            cumulativeStep = max(min(cumulativeStep, cumulativeClamp), -cumulativeClamp)
        } else {
            cumulativeStep = 0
        }
    }

    /// レートを既定値(1.0)に戻し、累積もクリア
    func reset() {
        setRate(1.0)
    }

    /// 現在のレートを返します
    var currentRate: Float {
        let raw = powf(rateBase, cumulativeStep)
        return min(max(raw, rateMin), rateMax)
    }

    // MARK: Static helpers

    /// 単発のステップからレートを求めるヘルパ
    static func rate(
        for step: Int,
        base: Float = 1.2,
        lowerBound: Float = 0.5,
        upperBound: Float = 3.0
    ) -> Float {
        let clampedStep = Float(Swift.max(Swift.min(step, 8), -8))
        let computed = powf(base, clampedStep)
        return Swift.min(Swift.max(computed, lowerBound), upperBound)
    }
}


