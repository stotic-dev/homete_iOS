//
//  ConfettiRainPiece.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/25.
//

import SwiftUI

/// 画面の上から降ってくる花吹雪の1枚
///
/// 落ち切ったら同じ紙片が上から降り直すため、枚数は増えも減りもしない。
/// 降るたびに生成・破棄していた頃と違って、画面上の枚数が読めるようになる。
struct ConfettiRainPiece: Identifiable {

    let id = UUID()
    /// 画面幅に対する横位置（0〜1）
    let horizontalRatio: Double
    let color: Color
    let size: CGSize
    /// 上から下まで落ち切るまでの時間
    let fallDuration: TimeInterval
    /// 降り始めをずらす時間
    let startOffset: TimeInterval
    /// 1秒あたりの回転量
    let spin: Angle
    /// 左右に流れる幅
    let swayWidth: Double
    /// 左右に流れる速さ（1秒あたりの往復回数）
    let swaySpeed: Double
    /// 左右に流れる初期位相
    let swayPhase: Double

}

extension ConfettiRainPiece {

    /// ある時点での紙片の見え方
    struct Appearance {

        let position: CGPoint
        let rotation: Angle
        /// 紙片の向き（-1〜1。0のとき真横を向いて見えなくなる）
        let flip: Double

    }

    /// 表示開始からの経過時間に対する見え方を求める
    /// - Parameters:
    ///   - time: 表示開始からの経過時間
    ///   - screenSize: 降らせる領域の大きさ
    /// - Returns: その時点での見え方
    func appearance(at time: TimeInterval, in screenSize: CGSize) -> Appearance {
        let margin = Self.margin
        let progress = ((time + startOffset) / fallDuration).truncatingRemainder(dividingBy: 1)
        let sway = sin(swayPhase + swaySpeed * time * 2 * .pi) * swayWidth
        // CGFloatとDoubleを混ぜた式は型チェックが極端に遅くなるため、Doubleに寄せて計算する
        let x = horizontalRatio * Double(screenSize.width) + sway
        let y = -margin + progress * (Double(screenSize.height) + margin * 2)

        return Appearance(
            position: CGPoint(x: x, y: y),
            rotation: .degrees(spin.degrees * time),
            flip: cos(swayPhase + swaySpeed * time * 2 * .pi)
        )
    }

}

extension ConfettiRainPiece {

    /// 画面外で折り返すための余白
    private static let margin: Double = 40
    private static let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .orange, .purple]

    /// 降らせる紙片をまとめて作る
    /// - Parameter count: 同時に画面へ出す枚数
    /// - Returns: 生成した紙片
    static func makePieces(count: Int = 60) -> [Self] {
        (0 ..< count).map { _ in
            let width = Double.random(in: 7 ... 13)
            let fallDuration = TimeInterval.random(in: 4 ... 8)

            return .init(
                horizontalRatio: Double.random(in: 0 ... 1),
                color: colors.randomElement() ?? .red,
                size: CGSize(width: width, height: width * Double.random(in: 1.2 ... 1.8)),
                fallDuration: fallDuration,
                // 落下時間の範囲でずらして、降り始めが揃わないようにする
                startOffset: TimeInterval.random(in: 0 ... fallDuration),
                spin: .degrees(Double.random(in: -180 ... 180)),
                swayWidth: Double.random(in: 10 ... 34),
                swaySpeed: Double.random(in: 0.2 ... 0.6),
                swayPhase: Double.random(in: 0 ... (2 * .pi))
            )
        }
    }

}
