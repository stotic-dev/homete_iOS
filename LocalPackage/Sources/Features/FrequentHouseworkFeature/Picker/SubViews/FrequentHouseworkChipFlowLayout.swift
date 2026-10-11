//
//  FrequentHouseworkChipFlowLayout.swift
//  LocalPackage
//

import SwiftUI

/// チップを内容の幅のまま左から並べ、入りきらなければ次の行へ送るレイアウト
/// - Note: 1つで幅を超えるチップには行の幅を上限として渡し、チップの中で折り返させる
struct FrequentHouseworkChipFlowLayout: Layout {

    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = makeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        // 左寄せにするため行の幅いっぱいを返す。最大サイズの問い合わせ（無限大）には内容の幅を返す
        let proposedWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        return CGSize(width: proposedWidth ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for row in makeRows(maxWidth: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for element in row.elements {
                subviews[element.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(element.size)
                )
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }

}

private extension FrequentHouseworkChipFlowLayout {

    struct Row {

        var elements: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0

    }

    func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if !current.elements.isEmpty, current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.elements.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.elements.append((index, size))
        }
        if !current.elements.isEmpty {
            rows.append(current)
        }
        return rows
    }

}
