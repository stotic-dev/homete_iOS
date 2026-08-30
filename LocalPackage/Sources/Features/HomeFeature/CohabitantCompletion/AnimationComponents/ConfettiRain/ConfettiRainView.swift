//
//  ConfettiRainView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/23.
//

import SwiftUI

/// クラッカーが弾けたあと、画面全体に降り続ける花吹雪
struct ConfettiRainView: View {

    @State private var pieces = ConfettiRainPiece.makePieces()
    @State private var startedAt = Date.now

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startedAt)

                for piece in pieces {
                    draw(piece, at: elapsed, in: size, context: context)
                }
            }
        }
    }

}

private extension ConfettiRainView {

    func draw(
        _ piece: ConfettiRainPiece,
        at elapsed: TimeInterval,
        in size: CGSize,
        context: GraphicsContext
    ) {
        let appearance = piece.appearance(at: elapsed, in: size)

        var context = context
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

}
