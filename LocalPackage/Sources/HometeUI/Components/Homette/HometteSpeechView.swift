//
//  HometteSpeechView.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// ほめっとと、その吹き出しのセリフを並べて表示する
///
/// セリフはほめっとの言葉なので、くだけた口調（「〜だよ」「〜してね」）にする（`ux-writing.md`の原則9）。
/// ほめっとの絵は読み上げず、セリフだけをVoiceOverで読み上げる。
public struct HometteSpeechView: View {

    let expression: HometteExpression
    let message: LocalizedStringResource
    let size: HometteView.Size

    public init(
        _ expression: HometteExpression,
        message: LocalizedStringResource,
        size: HometteView.Size = .small
    ) {
        self.expression = expression
        self.message = message
        self.size = size
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: .zero) {
            HometteView(expression, size: size)
            bubble
        }
    }

}

// MARK: UI定義

private extension HometteSpeechView {

    /// 吹き出しのしっぽは、ほめっとの側（左下）に付ける
    var bubble: some View {
        Text(message)
            .font(with: .body)
            .foregroundStyle(.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .background {
                RoundedRectangle(radius: .radius20)
                    .fill(.backgroundCard)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            }
            .background(alignment: .bottomLeading) {
                SpeechBubbleTail()
                    .fill(.backgroundCard)
                    .frame(width: .space16, height: .space16)
                    .offset(x: -.space8, y: -.space8)
            }
            .padding(.leading, .space8)
            .padding(.bottom, size.height / 4)
    }

}

/// 吹き出しのしっぽ。右上から左下へ細くなる三角形
struct SpeechBubbleTail: Shape {

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.closeSubpath()
        }
    }

}

#Preview("HometteSpeechView_短いセリフ", traits: .sizeThatFitsLayout) {
    HometteSpeechView(.rest, message: "今日はもうおしまい。おつかれさま")
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("HometteSpeechView_長いセリフ", traits: .sizeThatFitsLayout) {
    HometteSpeechView(.puzzled, message: "うまく読み込めなかったみたい。電波のいいところで、もう一度ためしてみてね")
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("HometteSpeechView_中くらいの大きさ", traits: .sizeThatFitsLayout) {
    HometteSpeechView(.praise, message: "やったね、洗濯おわり！", size: .medium)
        .padding(.space16)
        .background(.backgroundScreen)
}
