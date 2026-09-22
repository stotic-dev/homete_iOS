//
//  CrackerRibbon.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

/// クラッカーから飛び出す紙テープの1本
struct CrackerRibbon: Identifiable {

    /// 紙テープが消えるまでの時間
    static let lifetime: TimeInterval = 2.4

    let id = UUID()
    let color: Color
    /// テープの長さ
    let length: Double
    /// テープの太さ
    let width: Double
    /// 破裂した瞬間の速度（pt/秒）
    let velocity: CGVector
    /// 揺らぎの速さ（1秒あたりの往復回数）
    let swaySpeed: Double
    /// 揺らぎの初期位相
    let swayPhase: Double
    let delay: TimeInterval

}

extension CrackerRibbon {

    /// ある時点での紙テープの見え方
    struct Appearance {

        let position: CGPoint
        let rotation: Angle
        let opacity: Double

    }

    /// 破裂からの経過時間に対する見え方を求める
    ///
    /// テープは進行方向を向くので、傾きは位置ではなくそのときの速度から求める。
    /// これで、飛び出した直後は斜め上、落ちるにつれて下向きへ自然に倒れる。
    /// - Parameters:
    ///   - time: 破裂からの経過時間
    ///   - origin: 破裂した位置
    /// - Returns: その時点での見え方
    func appearance(at time: TimeInterval, origin: CGPoint) -> Appearance {
        let elapsed = max(0, time - delay)
        let displacement = CrackerPhysics.launchDisplacement(at: elapsed)
        let speedRatio = CrackerPhysics.launchSpeedRatio(at: elapsed)
        // CGFloatとDoubleを混ぜた式は型チェックが極端に遅くなるため、Doubleに寄せて計算する
        let launchX = Double(velocity.dx)
        let launchY = Double(velocity.dy)
        let currentX = launchX * speedRatio
        let currentY = launchY * speedRatio + CrackerPhysics.fallSpeed(at: elapsed)
        let sway = sin(swayPhase + swaySpeed * elapsed * 2 * .pi) * Self.swayAngle.radians
        let x = Double(origin.x) + launchX * displacement
        let y = Double(origin.y) + launchY * displacement + CrackerPhysics.fallDistance(at: elapsed)

        return Appearance(
            position: CGPoint(x: x, y: y),
            rotation: .radians(atan2(currentY, currentX) + sway),
            opacity: Self.opacity(at: elapsed)
        )
    }

}

extension CrackerRibbon {

    /// 射出方向（画面座標なので、負の角度が右上向き）
    private static let launchAngle = Angle.degrees(-52)
    /// 射出方向のばらつき
    ///
    /// 紙吹雪より狭くして、テープが束になって飛び出すように見せる。
    private static let spread = Angle.degrees(18)
    /// ひらひらと揺れる幅
    private static let swayAngle = Angle.degrees(16)
    /// 消え始めるまでの時間
    private static let fadeStart: TimeInterval = lifetime - 0.6
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]

    /// 破裂で飛び出す紙テープをまとめて作る
    /// - Parameter count: テープの本数
    /// - Returns: 生成したテープ
    static func makeBurst(count: Int = 16) -> [Self] {
        (0 ..< count).map { _ in
            let angle = Angle.degrees(launchAngle.degrees + Double.random(in: -spread.degrees ... spread.degrees))
            let speed = Double.random(in: 520 ... 1050)

            return .init(
                color: colors.randomElement() ?? .red,
                length: Double.random(in: 44 ... 88),
                width: Double.random(in: 5 ... 7),
                velocity: CGVector(dx: cos(angle.radians) * speed, dy: sin(angle.radians) * speed),
                swaySpeed: Double.random(in: 0.8 ... 1.8),
                swayPhase: Double.random(in: 0 ... (2 * .pi)),
                delay: TimeInterval.random(in: 0 ... 0.05)
            )
        }
    }

    /// 寿命の終わりにかけて薄くする
    private static func opacity(at elapsed: TimeInterval) -> Double {
        guard elapsed > fadeStart else { return 1 }
        return max(0, 1 - (elapsed - fadeStart) / (lifetime - fadeStart))
    }

}
