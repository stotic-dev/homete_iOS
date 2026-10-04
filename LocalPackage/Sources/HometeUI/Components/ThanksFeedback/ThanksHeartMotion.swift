//
//  ThanksHeartMotion.swift
//  LocalPackage
//

import CoreGraphics
import Foundation

/// ありがとうを伝えたときに出すハートの動き
///
/// 経過時間だけから見え方が決まる閉じた式にしてあるため、ハートごとに状態を持って毎フレーム更新する必要がなく、
/// `Canvas`の描画だけで済ませられる。乱数を使わずに並べているのは、同じ経過時間なら必ず同じ絵になり、
/// Previewのスナップショットが撮るたびに変わらないようにするため。
enum ThanksHeartMotion {

    /// 演出が終わるまでの時間
    static let duration: TimeInterval = 1.1

    /// ある時点でのハートの見え方
    struct Appearance: Equatable {

        /// 弾けた位置からのずれ
        let offset: CGVector
        /// 描く大きさ（pt）
        let size: CGFloat
        let opacity: Double

    }

}

// MARK: 中央のハート

extension ThanksHeartMotion {

    /// 中央に出る大きなハートの大きさ
    static let centerHeartSize: CGFloat = 88

    /// 中央のハートがふくらみ切るまでの時間
    private static let centerPopDuration: TimeInterval = 0.3
    /// 中央のハートが消え始めるまでの時間
    private static let centerFadeStart: TimeInterval = 0.7

    /// 中央に出る大きなハートの見え方
    /// - Parameters:
    ///   - time: 演出の開始からの経過時間
    ///   - isReduceMotion: 視差効果を減らす設定が有効か。有効なら大きさを変えず、ふわっと出して消すだけにする
    /// - Returns: その時点での見え方
    static func centerHeart(at time: TimeInterval, isReduceMotion: Bool) -> Appearance {
        let elapsed = max(0, time)
        let fadeOut = fadeOutRatio(at: elapsed, from: centerFadeStart)

        guard !isReduceMotion else {
            let fadeIn = min(1, elapsed / centerPopDuration)
            return .init(offset: .zero, size: centerHeartSize, opacity: fadeIn * fadeOut)
        }

        // 小さく出てから少し行き過ぎるほどふくらみ、元の大きさに落ち着く
        let progress = min(1, elapsed / centerPopDuration)
        let scale = 0.4 + 0.6 * easeOutBack(progress)
        // 消えながら少しだけ浮き上がり、気持ちが相手に飛んでいったように見せる
        let rise = max(0, elapsed - centerFadeStart) * 80

        return .init(
            offset: CGVector(dx: 0, dy: -rise),
            size: centerHeartSize * scale,
            opacity: min(1, elapsed / 0.08) * fadeOut
        )
    }

    /// 少し行き過ぎてから戻るイージング（0〜1を受け取り、途中で1を超える）
    private static func easeOutBack(_ progress: Double) -> Double {
        let overshoot = 1.9
        let shifted = progress - 1
        return 1 + (overshoot + 1) * pow(shifted, 3) + overshoot * pow(shifted, 2)
    }

}

// MARK: 飛び散る小さなハート

extension ThanksHeartMotion {

    /// 中央のハートから飛び散る小さなハートの1つ
    struct Piece: Equatable {

        /// 飛び出す向き
        let angle: Double
        /// 飛び出す速さ（pt/秒）
        let speed: Double
        /// 描く大きさ（pt）
        let size: CGFloat
        /// 濃いほうの色で描くか。色を交互に変えて、同じハートが並んだだけに見えないようにする
        let isPrimaryColor: Bool
        /// 中央のハートがふくらんでから飛び出すまでの遅れ
        let delay: TimeInterval

    }

    /// 小さなハートの数
    private static let pieceCount = 12
    /// 小さなハートが飛び出す勢いが空気抵抗で失われる速さ
    private static let pieceDragRate: Double = 4.2
    /// 小さなハートが浮き上がる速さ（pt/秒）
    private static let pieceRiseSpeed: Double = 70
    /// 小さなハートが消え始めるまでの時間（飛び出してからの経過時間）
    private static let pieceFadeStart: TimeInterval = 0.45
    /// 小さなハートがふくらみ切るまでの時間
    private static let piecePopDuration: TimeInterval = 0.12

    /// 飛び散る小さなハートをまとめて作る
    ///
    /// 全方向に等間隔で並べ、速さ・大きさ・遅れを3通りで回して自然なばらつきに見せる。
    static let pieces: [Piece] = (0 ..< pieceCount).map { index in
        let speeds: [Double] = [300, 380, 330]
        let sizes: [CGFloat] = [18, 24, 15]
        let delays: [TimeInterval] = [0.12, 0.16, 0.14]
        // 真上から少しずらして始め、真上と真下に1つずつ揃って並ぶのを避ける
        let angle = -Double.pi / 2 + 0.2 + Double(index) / Double(pieceCount) * 2 * .pi

        return .init(
            angle: angle,
            speed: speeds[index % speeds.count],
            size: sizes[index % sizes.count],
            isPrimaryColor: index.isMultiple(of: 2),
            delay: delays[index % delays.count]
        )
    }

    /// 小さなハートの見え方
    /// - Parameters:
    ///   - piece: 対象のハート
    ///   - time: 演出の開始からの経過時間
    /// - Returns: その時点での見え方。飛び出す前は透明
    static func appearance(of piece: Piece, at time: TimeInterval) -> Appearance {
        let elapsed = time - piece.delay
        guard elapsed > 0 else {
            return .init(offset: .zero, size: 0, opacity: 0)
        }

        let distance = piece.speed * (1 - exp(-pieceDragRate * elapsed)) / pieceDragRate
        let offset = CGVector(
            dx: cos(piece.angle) * distance,
            dy: sin(piece.angle) * distance - pieceRiseSpeed * elapsed
        )
        let scale = min(1, elapsed / piecePopDuration)

        return .init(
            offset: offset,
            size: piece.size * scale,
            opacity: fadeOutRatio(at: elapsed, from: pieceFadeStart, end: duration - piece.delay)
        )
    }

}

private extension ThanksHeartMotion {

    /// 消えていく途中の不透明度（消え始める前は1、演出の終わりで0）
    static func fadeOutRatio(
        at elapsed: TimeInterval,
        from start: TimeInterval,
        end: TimeInterval = duration
    ) -> Double {
        guard elapsed > start else { return 1 }
        return max(0, 1 - (elapsed - start) / (end - start))
    }

}
