//
//  HouseworkExecutorSelectionContent.swift
//  LocalPackage
//

import HometeResources
import HometeUI
import SwiftUI

/// 家事の担当者を選ぶチェックリスト
public struct HouseworkExecutorSelectionContent: View {

    public struct Row: Equatable, Identifiable {

        public let userId: String
        public let userName: String
        public let isSelected: Bool
        /// 選択を切り替えられるかどうか（人数の上限に達した未選択のメンバーと、`isLocked`の担当者は選べない）
        public let isEnabled: Bool
        /// 外せない担当者かどうか（完了済みの家事に手伝った人を足すときの、もともとの担当者）
        ///
        /// タップはできないが、担当者として数えられていることが伝わるよう薄くしない
        public let isLocked: Bool
        /// 配分した割合とポイント。未選択、または配分が確定できないときは`nil`
        public let allocation: Allocation?

        public init(
            userId: String,
            userName: String,
            isSelected: Bool,
            isEnabled: Bool,
            isLocked: Bool,
            allocation: Allocation?
        ) {
            self.userId = userId
            self.userName = userName
            self.isSelected = isSelected
            self.isEnabled = isEnabled
            self.isLocked = isLocked
            self.allocation = allocation
        }

        public var id: String {
            userId
        }

    }

    public struct Allocation: Equatable {

        public let percentage: Int
        public let point: Int

        public init(
            percentage: Int,
            point: Int
        ) {
            self.percentage = percentage
            self.point = point
        }

    }

    let rows: [Row]
    let onToggle: (String) -> Void

    public init(
        rows: [Row],
        onToggle: @escaping (String) -> Void
    ) {
        self.rows = rows
        self.onToggle = onToggle
    }

    public var body: some View {
        VStack(spacing: .zero) {
            ForEach(rows) { row in
                rowContent(row)
                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
        .background {
            RoundedRectangle(radius: .radius12)
                .fill(.backgroundCard)
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
                    .foregroundStyle(row.isSelected ? Color.fillAccent : Color.textSecondary)
                Text(row.userName)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
                Spacer()
                if let allocation = row.allocation {
                    Text("\(allocation.percentage)%・\(allocation.point)pt", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
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
        .opacity(row.isEnabled || row.isLocked ? 1 : 0.4)
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
                isLocked: false,
                allocation: .init(percentage: 100, point: 10)
            ),
            .init(
                userId: "partner",
                userName: "はなこ",
                isSelected: false,
                isEnabled: true,
                isLocked: false,
                allocation: nil
            ),
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
                isLocked: false,
                allocation: .init(percentage: 34, point: 4)
            ),
            .init(
                userId: "partner",
                userName: "はなこ",
                isSelected: true,
                isEnabled: true,
                isLocked: false,
                allocation: .init(percentage: 33, point: 3)
            ),
            .init(
                userId: "child",
                userName: "じろう",
                isSelected: true,
                isEnabled: true,
                isLocked: false,
                allocation: .init(percentage: 33, point: 3)
            ),
        ],
        onToggle: { _ in }
    )
    .padding()
}

#Preview("HouseworkExecutorSelectionContent_外せない担当者", traits: .sizeThatFitsLayout) {
    HouseworkExecutorSelectionContent(
        rows: [
            .init(
                userId: "own",
                userName: "たいち",
                isSelected: true,
                isEnabled: false,
                isLocked: true,
                allocation: .init(percentage: 100, point: 10)
            ),
            .init(
                userId: "partner",
                userName: "はなこ",
                isSelected: false,
                isEnabled: true,
                isLocked: false,
                allocation: nil
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
                isLocked: false,
                allocation: .init(percentage: 100, point: 1)
            ),
            .init(
                userId: "partner",
                userName: "はなこ",
                isSelected: false,
                isEnabled: false,
                isLocked: false,
                allocation: nil
            ),
        ],
        onToggle: { _ in }
    )
    .padding()
}
#endif
