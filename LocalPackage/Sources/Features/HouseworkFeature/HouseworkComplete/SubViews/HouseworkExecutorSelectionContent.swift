//
//  HouseworkExecutorSelectionContent.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 家事の担当者を選ぶチェックリスト
struct HouseworkExecutorSelectionContent: View {

    struct Row: Equatable, Identifiable {

        let userId: String
        let userName: String
        let isSelected: Bool
        /// 選択を切り替えられるかどうか（人数の上限に達した未選択のメンバーは選べない）
        let isEnabled: Bool
        /// 配分した割合とポイント。未選択、または配分が確定できないときは`nil`
        let allocation: Allocation?

        var id: String {
            userId
        }

    }

    struct Allocation: Equatable {

        let percentage: Int
        let point: Int

    }

    let rows: [Row]
    let onToggle: (String) -> Void

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(rows) { row in
                rowContent(row)
                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.subSurface)
        }
    }

}

private extension HouseworkExecutorSelectionContent {

    func rowContent(_ row: Row) -> some View {
        Button {
            onToggle(row.userId)
        } label: {
            HStack(spacing: .space8) {
                Image(systemName: row.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(row.isSelected ? Color.accent : Color.onSurfaceVariant)
                Text(row.userName)
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                Spacer()
                if let allocation = row.allocation {
                    Text("\(allocation.percentage)%・\(allocation.point)pt")
                        .font(with: .body)
                        .foregroundStyle(.onSurfaceVariant)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!row.isEnabled)
        .opacity(row.isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(row.isSelected ? .isSelected : [])
    }

}

#if DEBUG
#Preview("HouseworkExecutorSelectionContent_自分だけ", traits: .sizeThatFitsLayout) {
    HouseworkExecutorSelectionContent(
        rows: [
            .init(
                userId: "own",
                userName: "たいち",
                isSelected: true,
                isEnabled: true,
                allocation: .init(percentage: 100, point: 10)
            ),
            .init(userId: "partner", userName: "はなこ", isSelected: false, isEnabled: true, allocation: nil),
        ],
        onToggle: { _ in }
    )
    .padding()
}

#Preview("HouseworkExecutorSelectionContent_3人で分担", traits: .sizeThatFitsLayout) {
    HouseworkExecutorSelectionContent(
        rows: [
            .init(
                userId: "own",
                userName: "たいち",
                isSelected: true,
                isEnabled: true,
                allocation: .init(percentage: 34, point: 4)
            ),
            .init(
                userId: "partner",
                userName: "はなこ",
                isSelected: true,
                isEnabled: true,
                allocation: .init(percentage: 33, point: 3)
            ),
            .init(
                userId: "child",
                userName: "じろう",
                isSelected: true,
                isEnabled: true,
                allocation: .init(percentage: 33, point: 3)
            ),
        ],
        onToggle: { _ in }
    )
    .padding()
}

#Preview("HouseworkExecutorSelectionContent_人数の上限", traits: .sizeThatFitsLayout) {
    HouseworkExecutorSelectionContent(
        rows: [
            .init(
                userId: "own",
                userName: "たいち",
                isSelected: true,
                isEnabled: true,
                allocation: .init(percentage: 100, point: 1)
            ),
            .init(userId: "partner", userName: "はなこ", isSelected: false, isEnabled: false, allocation: nil),
        ],
        onToggle: { _ in }
    )
    .padding()
}
#endif
