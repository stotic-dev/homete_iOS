//
//  CrackerConfettiPiece.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

/// クラッカーから飛び出す紙吹雪の1枚
struct CrackerConfettiPiece: Identifiable {

    /// 紙片が消えるまでの時間
    static let lifetime: TimeInterval = 2.4

    let id = UUID()
    /// 紙片の大きさ
    let size: CGSize
    let color: Color
    /// 破裂した瞬間の速度（pt/秒）
    let velocity: CGVector
    /// 1秒あたりの回転量
    let spin: Angle
    /// ひらひらと裏返る速さ（1秒あたりの往復回数）
    let flutterSpeed: Double
    /// ひらひらの初期位相
    let flutterPhase: Double
    /// 飛び出すまでのわずかな遅れ
    ///
    /// 全部が完全に同時だと一枚の板のように見えてしまうため、ごくわずかにばらつかせる。
    let delay: TimeInterval

}

extension CrackerConfettiPiece {

    /// ある時点での紙片の見え方
    struct Appearance {

        let position: CGPoint
        let rotation: Angle
        /// 紙片の向き（-1〜1。0のとき真横を向いて見えなくなる）
        let flip: Double
        let opacity: Double

    }

    /// 破裂からの経過時間に対する見え方を求める
    /// - Parameters:
    ///   - time: 破裂からの経過時間
    ///   - origin: 破裂した位置
    /// - Returns: その時点での見え方
    func appearance(at time: TimeInterval, origin: CGPoint) -> Appearance {
        let elapsed = max(0, time - delay)
        let displacement = CrackerPhysics.launchDisplacement(at: elapsed)
        // CGFloatとDoubleを混ぜた式は型チェックが極端に遅くなるため、Doubleに寄せて計算する
        let x = Double(origin.x) + Double(velocity.dx) * displacement
        let y = Double(origin.y) + Double(velocity.dy) * displacement + CrackerPhysics.fallDistance(at: elapsed)

        return Appearance(
            position: CGPoint(x: x, y: y),
            rotation: .degrees(spin.degrees * elapsed),
            flip: cos(flutterPhase + flutterSpeed * elapsed * 2 * .pi),
            opacity: Self.opacity(at: elapsed)
        )
    }

}

extension CrackerConfettiPiece {

    /// 射出方向（画面座標なので、負の角度が右上向き）
    private static let launchAngle = Angle.degrees(-52)
    /// 射出方向のばらつき
    private static let spread = Angle.degrees(26)
    /// 消え始めるまでの時間
    private static let fadeStart: TimeInterval = lifetime - 0.6
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]

    /// 破裂で飛び出す紙吹雪をまとめて作る
    /// - Parameter count: 紙片の枚数
    /// - Returns: 生成した紙片
    static func makeBurst(count: Int = 110) -> [Self] {
        (0 ..< count).map { _ in
            let angle = Angle.degrees(launchAngle.degrees + Double.random(in: -spread.degrees ... spread.degrees))
            let speed = Double.random(in: 620 ... 1450)
            let width = Double.random(in: 6 ... 11)

            return .init(
                size: CGSize(width: width, height: width * Double.random(in: 1 ... 1.8)),
                color: colors.randomElement() ?? .red,
                velocity: CGVector(dx: cos(angle.radians) * speed, dy: sin(angle.radians) * speed),
                spin: .degrees(Double.random(in: -720 ... 720)),
                flutterSpeed: Double.random(in: 1.4 ... 3.2),
                flutterPhase: Double.random(in: 0 ... (2 * .pi)),
                delay: TimeInterval.random(in: 0 ... 0.06)
            )
        }
    }

    /// 寿命の終わりにかけて薄くする
    private static func opacity(at elapsed: TimeInterval) -> Double {
        guard elapsed > fadeStart else { return 1 }
        return max(0, 1 - (elapsed - fadeStart) / (lifetime - fadeStart))
    }

}
