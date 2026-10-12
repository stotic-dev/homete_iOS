//
//  MemberShareSummary.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// メンバーごとの分担を、メンバーの色で塗り分けた1本のバーと、名前と値の一覧で見せる
///
/// バーの色は`MemberChartPalette`と同じく、渡された並び（自分が先頭）の順に割り当てる。
/// 値が0のメンバーはバーに出さず、一覧には出す。
public struct MemberShareSummary: View {

    let items: [Item]

    public init(items: [Item]) {
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            MemberShareBar(values: items.map(\.value))
                .accessibilityHidden(true)
            VStack(spacing: .space8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(item, color: MemberChartPalette.color(at: index))
                }
            }
        }
    }

}

public extension MemberShareSummary {

    struct Item: Identifiable, Sendable {

        public let id: String
        /// メンバーの名前。ユーザーが入力した文字なので翻訳しない
        public let name: String
        /// バーの長さの元にする値
        public let value: Int
        /// 一覧の右側に出す値の説明（例: 3件・60pt）
        public let detail: LocalizedStringResource

        public init(id: String, name: String, value: Int, detail: LocalizedStringResource) {
            self.id = id
            self.name = name
            self.value = value
            self.detail = detail
        }

    }

}

// MARK: - UI定義

private extension MemberShareSummary {

    func row(_ item: Item, color: Color) -> some View {
        HStack(spacing: .space8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(verbatim: item.name)
                .font(with: .body)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
            Spacer(minLength: .space8)
            Text(item.detail)
                .font(with: .headLineS)
                .monospacedDigit()
                .foregroundStyle(.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

}

/// 値の割合で塗り分けた、角の丸い1本のバー
struct MemberShareBar: View {

    let values: [Int]

    private let height: CGFloat = 12
    private let gap: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let total = values.reduce(0, +)
            if total > 0 {
                let segments = values.enumerated().filter { $0.element > 0 }
                let width = geometry.size.width - gap * CGFloat(segments.count - 1)
                HStack(spacing: gap) {
                    ForEach(segments, id: \.offset) { index, value in
                        Capsule()
                            .fill(MemberChartPalette.color(at: index))
                            .frame(width: width * CGFloat(value) / CGFloat(total))
                    }
                }
            } else {
                // まだ誰も実績が無いときは、空の器だけを見せる
                Capsule()
                    .fill(.fillAccentSubtle)
            }
        }
        .frame(height: height)
    }

}

#Preview("MemberShareSummary_2人", traits: .sizeThatFitsLayout) {
    MemberShareSummary(items: [
        .init(id: "1", name: "たいち", value: 580, detail: "29件・580pt"),
        .init(id: "2", name: "はなこ", value: 420, detail: "21件・420pt"),
    ])
    .padding(.space16)
}

#Preview("MemberShareSummary_実績0のメンバーあり", traits: .sizeThatFitsLayout) {
    MemberShareSummary(items: [
        .init(id: "1", name: "たいち", value: 60, detail: "3件・60pt"),
        .init(id: "2", name: "はなこ", value: 0, detail: "0件・0pt"),
        .init(id: "3", name: "じろう", value: 20, detail: "1件・20pt"),
    ])
    .padding(.space16)
}

#Preview("MemberShareSummary_全員0", traits: .sizeThatFitsLayout) {
    MemberShareSummary(items: [
        .init(id: "1", name: "たいち", value: 0, detail: "0件・0pt"),
        .init(id: "2", name: "はなこ", value: 0, detail: "0件・0pt"),
    ])
    .padding(.space16)
}
