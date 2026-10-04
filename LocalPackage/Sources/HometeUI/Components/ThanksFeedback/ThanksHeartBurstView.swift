//
//  ThanksHeartBurstView.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// ありがとうを伝えたときに、中央のハートがふくらんで小さなハートが飛び散る演出
///
/// 表示されたときから再生を始め、終わったら`completion`を呼ぶ。
struct ThanksHeartBurstView: View {

    @Environment(\.accessibilityReduceMotion) private var isReduceMotion

    /// 演出が終わったら呼ばれるクロージャ
    let completion: () -> Void

    @State private var startedAt = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            ThanksHeartCanvas(
                elapsed: timeline.date.timeIntervalSince(startedAt),
                isReduceMotion: isReduceMotion
            )
        }
        .task {
            do {
                try await Task.sleep(for: .seconds(ThanksHeartMotion.duration))
            } catch {
                // 途中で画面から外れた場合は、終わったことにしない
                return
            }
            completion()
        }
    }

}

/// 演出のある時点の絵を描く
///
/// 経過時間を外から渡すことで、Previewでは途中の1コマを固定して描けるようにしている。
struct ThanksHeartCanvas: View {

    /// 演出の開始からの経過時間
    let elapsed: TimeInterval
    /// 視差効果を減らす設定が有効か。有効なら中央のハートを出して消すだけにする
    let isReduceMotion: Bool

    var body: some View {
        // ハートは1つずつViewにせず`Canvas`にまとめて描く。描く図柄は、家事セルで伝えたかどうかを示す
        // ハートと同じSF Symbolを大きめの1つだけ用意し、それを縮めて使い回す
        Canvas { context, size in
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.45)

            if !isReduceMotion {
                for piece in ThanksHeartMotion.pieces {
                    draw(
                        ThanksHeartMotion.appearance(of: piece, at: elapsed),
                        symbol: piece.isPrimaryColor ? SymbolID.primary : SymbolID.secondary,
                        from: origin,
                        in: context
                    )
                }
            }
            draw(
                ThanksHeartMotion.centerHeart(at: elapsed, isReduceMotion: isReduceMotion),
                symbol: SymbolID.primary,
                from: origin,
                in: context
            )
        } symbols: {
            heartSymbol(color: .thanksHeart)
                .tag(SymbolID.primary)
            heartSymbol(color: .pink.opacity(0.8))
                .tag(SymbolID.secondary)
        }
        .accessibilityHidden(true)
    }

}

private extension ThanksHeartCanvas {

    enum SymbolID {

        static let primary = 0
        static let secondary = 1

    }

    func heartSymbol(color: Color) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: ThanksHeartMotion.centerHeartSize))
            .foregroundStyle(color)
    }

    func draw(
        _ appearance: ThanksHeartMotion.Appearance,
        symbol id: Int,
        from origin: CGPoint,
        in context: GraphicsContext
    ) {
        guard appearance.opacity > 0,
              appearance.size > 0,
              let symbol = context.resolveSymbol(id: id) else { return }

        var context = context
        context.opacity = appearance.opacity
        context.translateBy(x: origin.x + appearance.offset.dx, y: origin.y + appearance.offset.dy)
        let scale = appearance.size / ThanksHeartMotion.centerHeartSize
        context.scaleBy(x: scale, y: scale)
        context.draw(symbol, at: .zero)
    }

}

#if DEBUG
#Preview("ThanksHeartCanvas_飛び散っている途中") {
    ThanksHeartCanvas(elapsed: 0.4, isReduceMotion: false)
}

#Preview("ThanksHeartCanvas_視差効果を減らす") {
    ThanksHeartCanvas(elapsed: 0.4, isReduceMotion: true)
}
#endif
