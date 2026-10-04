//
//  HouseworkDetailMemoContent.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事詳細のメモ欄
struct HouseworkDetailMemoContent: View {

    /// 表示するメモ。内容が無ければ`nil`
    let memo: HouseworkMemo?
    /// メモを編集できるか（未完了の家事だけ）
    let isEditable: Bool
    /// チェックの保存中か。保存中は編集ボタンを押せなくする
    /// - Note: チェックは見た目を変えないよう非活性にせず、保存中のタップは呼び出し側で無視する
    var isUpdating = false
    let onTapEdit: () -> Void
    let onToggle: (HouseworkMemoChecklistItem.ID) -> Void

    var body: some View {
        SectionCard("メモ") {
            if let memo {
                HouseworkMemoContent(memo: memo, isEditable: isEditable, onToggle: onToggle)
                if isEditable {
                    Divider()
                }
            }
            if isEditable {
                editButton()
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkDetailMemoContent {

    func editButton() -> some View {
        Button {
            onTapEdit()
        } label: {
            if memo == nil {
                Label("メモを追加", systemImage: "plus")
            } else {
                Label("メモを編集", systemImage: "pencil")
            }
        }
        .font(with: .body)
        .disabled(isUpdating)
    }

}

#if DEBUG
#Preview("HouseworkDetailMemoContent_メモなし", traits: .sizeThatFitsLayout) {
    HouseworkDetailMemoContent(memo: nil, isEditable: true, onTapEdit: {}, onToggle: { _ in })
        .padding()
}

#Preview("HouseworkDetailMemoContent_編集できる", traits: .sizeThatFitsLayout) {
    HouseworkDetailMemoContent(
        memo: .init(
            text: "駅前のスーパーで",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: true),
                .init(id: "2", title: "卵", isChecked: false),
            ]
        ),
        isEditable: true,
        onTapEdit: {},
        onToggle: { _ in }
    )
    .padding()
}

#Preview("HouseworkDetailMemoContent_閲覧のみ", traits: .sizeThatFitsLayout) {
    HouseworkDetailMemoContent(
        memo: .init(text: "駅前のスーパーで", checklist: [.init(id: "1", title: "牛乳", isChecked: true)]),
        isEditable: false,
        onTapEdit: {},
        onToggle: { _ in }
    )
    .padding()
}
#endif
