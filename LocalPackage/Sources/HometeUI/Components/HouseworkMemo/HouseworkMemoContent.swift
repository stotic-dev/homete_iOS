//
//  HouseworkMemoContent.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import SwiftUI

/// 家事メモの表示。チェックリストは、編集できるときだけチェックを切り替えられる
public struct HouseworkMemoContent: View {

    let memo: HouseworkMemo
    let isEditable: Bool
    let onToggle: (HouseworkMemoChecklistItem.ID) -> Void

    public init(
        memo: HouseworkMemo,
        isEditable: Bool,
        onToggle: @escaping (HouseworkMemoChecklistItem.ID) -> Void
    ) {
        self.memo = memo
        self.isEditable = isEditable
        self.onToggle = onToggle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            if !memo.text.isEmpty {
                Text(memo.text)
                    .font(with: .body)
                    .foregroundStyle(.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            if !memo.checklist.isEmpty {
                VStack(alignment: .leading, spacing: .zero) {
                    ForEach(memo.checklist) { item in
                        checklistItemRow(item)
                    }
                }
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkMemoContent {

    func checklistItemRow(_ item: HouseworkMemoChecklistItem) -> some View {
        Button {
            onToggle(item.id)
        } label: {
            HStack(spacing: .space8) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .accent : .onSurfaceVariant)
                    .font(with: .headLineS)
                Text(item.title)
                    .font(with: .body)
                    .foregroundStyle(item.isChecked ? .onSurfaceVariant : .onSurface)
                    .strikethrough(item.isChecked)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: .zero)
            }
            .padding(.vertical, .space8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityAddTraits(item.isChecked ? .isSelected : [])
    }

}

#if DEBUG
#Preview("HouseworkMemoContent_編集できる", traits: .sizeThatFitsLayout) {
    HouseworkMemoContent(
        memo: .init(
            text: "駅前のスーパーで。卵は特売日に",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: true),
                .init(id: "2", title: "卵", isChecked: false),
            ]
        ),
        isEditable: true,
        onToggle: { _ in }
    )
    .padding()
}

#Preview("HouseworkMemoContent_閲覧のみ", traits: .sizeThatFitsLayout) {
    HouseworkMemoContent(
        memo: .init(
            text: "",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: true),
                .init(id: "2", title: "卵", isChecked: false),
            ]
        ),
        isEditable: false,
        onToggle: { _ in }
    )
    .padding()
}
#endif
