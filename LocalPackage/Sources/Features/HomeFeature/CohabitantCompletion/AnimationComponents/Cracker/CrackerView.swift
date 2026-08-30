//
//  CrackerView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import HometeUI
import SwiftUI

/// クラッカーが弾けて紙吹雪と紙テープが飛び散る演出
///
/// 紙片は`Canvas`にまとめて描画する。1枚ずつをSwiftUIのViewにすると、
/// 100枚規模ではレイアウトが毎フレーム走って目に見えて重くなるため。
struct CrackerView: View {

    /// 表示されてからクラッカーが弾けるまでの時間
    ///
    /// 一瞬だけ引いてから弾ける「溜め」を作るための間。
    private static let windUpDuration: TimeInterval = 0.55

    /// クラッカー本体の大きさ
    private static let popperSize: CGFloat = 96

    /// アニメーション終了したら呼ばれるクロージャ
    let completion: () -> Void

    @State private var phase = Phase.waiting
    @State private var burstStartedAt: Date?
    @State private var confettis: [CrackerConfettiPiece] = []
    @State private var ribbons: [CrackerRibbon] = []

    var body: some View {
        ZStack {
            burst()
            popper()
        }
        .task {
            await fire()
        }
        // 溜めの手応えと破裂の衝撃を、見た目のタイミングに合わせて返す
        .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: phase) { _, phase in
            phase == .aiming
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: phase) { _, phase in
            phase == .bursting
        }
    }

}

// MARK: UI定義

private extension CrackerView {

    /// 飛び散る紙片
    func burst() -> some View {
        TimelineView(.animation(paused: phase != .bursting)) { timeline in
            Canvas { context, size in
                let elapsed = burstStartedAt.map { timeline.date.timeIntervalSince($0) } ?? 0
                let origin = Self.burstOrigin(in: size)

                // テープは紙吹雪の奥に置く
                for ribbon in ribbons {
                    draw(ribbon, at: elapsed, from: origin, in: context)
                }
                for confetti in confettis {
                    draw(confetti, at: elapsed, from: origin, in: context)
                }
            }
        }
    }

    /// クラッカー本体
    func popper() -> some View {
        Image(systemName: "party.popper.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Self.popperSize, height: Self.popperSize)
            .foregroundStyle(.orange, .yellow)
            .symbolEffect(.bounce, value: phase == .bursting)
            .rotationEffect(phase.popperAngle, anchor: .bottomLeading)
            .scaleEffect(phase.popperScale, anchor: .bottomLeading)
            .padding(.leading, .space16)
            .padding(.bottom, .space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    func draw(
        _ piece: CrackerConfettiPiece,
        at elapsed: TimeInterval,
        from origin: CGPoint,
        in context: GraphicsContext
    ) {
        let appearance = piece.appearance(at: elapsed, origin: origin)
        guard appearance.opacity > 0 else { return }

        var context = context
        context.opacity = appearance.opacity
        context.translateBy(x: appearance.position.x, y: appearance.position.y)
        context.rotate(by: appearance.rotation)
        // 横方向だけ縮めることで、紙が裏返りながら舞う見え方にする
        context.scaleBy(x: CGFloat(appearance.flip), y: 1)

        let rect = CGRect(
            x: -piece.size.width / 2,
            y: -piece.size.height / 2,
            width: piece.size.width,
            height: piece.size.height
        )
        context.fill(Path(rect), with: .color(piece.color))
    }

    func draw(
        _ ribbon: CrackerRibbon,
        at elapsed: TimeInterval,
        from origin: CGPoint,
        in context: GraphicsContext
    ) {
        let appearance = ribbon.appearance(at: elapsed, origin: origin)
        guard appearance.opacity > 0 else { return }

        var context = context
        context.opacity = appearance.opacity
        context.translateBy(x: appearance.position.x, y: appearance.position.y)
        context.rotate(by: appearance.rotation)

        let rect = CGRect(
            x: -ribbon.length / 2,
            y: -ribbon.width / 2,
            width: ribbon.length,
            height: ribbon.width
        )
        context.fill(Path(roundedRect: rect, cornerRadius: CGFloat(ribbon.width / 2)), with: .color(ribbon.color))
    }

}

// MARK: プレゼンテーションロジック

private extension CrackerView {

    /// 溜めから破裂までを進めて、紙片が飛び切ったら終了を伝える
    func fire() async {
        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
            phase = .aiming
        }
        try? await Task.sleep(for: .seconds(Self.windUpDuration))

        confettis = CrackerConfettiPiece.makeBurst()
        ribbons = CrackerRibbon.makeBurst()
        burstStartedAt = .now
        withAnimation(.spring(duration: 0.45, bounce: 0.6)) {
            phase = .bursting
        }

        try? await Task.sleep(for: .seconds(CrackerConfettiPiece.lifetime))
        confettis.removeAll()
        ribbons.removeAll()
        completion()
    }

    /// 紙片が飛び出す位置（クラッカーの筒口のあたり）
    static func burstOrigin(in size: CGSize) -> CGPoint {
        CGPoint(
            x: .space16 + popperSize * 0.78,
            y: size.height - .space24 - popperSize * 0.72
        )
    }

}

private extension CrackerView {

    /// クラッカーの状態
    enum Phase {

        /// 表示された直後
        case waiting
        /// 弾ける直前に引いている
        case aiming
        /// 弾けた
        case bursting

        /// クラッカー本体の傾き
        var popperAngle: Angle {
            switch self {
            case .waiting: .zero
            case .aiming: .degrees(-14)
            case .bursting: .degrees(8)
            }
        }

        /// クラッカー本体の拡大率
        var popperScale: Double {
            switch self {
            case .waiting: 1
            case .aiming: 0.94
            case .bursting: 1.12
            }
        }

    }

}
