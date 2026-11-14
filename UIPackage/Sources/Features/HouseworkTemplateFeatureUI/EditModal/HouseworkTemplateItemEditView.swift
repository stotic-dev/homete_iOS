//
//  HouseworkTemplateItemEditView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事追加・編集モーダルの中身（新規・編集兼用）
/// - Note: メモの編集シート・閉じる操作は`HouseworkTemplateItemEditModalScreen`が受け持つ。
///         `NavigationStack`の中に置かれる前提でツールバーの項目を並べる
public struct HouseworkTemplateItemEditView: View {

    @Binding var input: TemplateItemEditInput
    @FocusState var isShowingKeyboard: Bool

    let mode: HouseworkTemplateEditMode
    let onTapClose: () -> Void
    let onTapMemo: () -> Void
    let onTapConfirm: () -> Void

    public init(
        input: Binding<TemplateItemEditInput>,
        isShowingKeyboard: FocusState<Bool> = .init(),
        mode: HouseworkTemplateEditMode,
        onTapClose: @escaping () -> Void = {},
        onTapMemo: @escaping () -> Void = {},
        onTapConfirm: @escaping () -> Void
    ) {
        _input = input
        _isShowingKeyboard = isShowingKeyboard
        self.mode = mode
        self.onTapClose = onTapClose
        self.onTapMemo = onTapMemo
        self.onTapConfirm = onTapConfirm
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            inputTitleField()
            inputPointPicker()
            inputRecurrenceSelector()
            HouseworkMemoRow(hasContent: input.memo.hasContent, titleFont: .headLineS) {
                onTapMemo()
            }
            Spacer()
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space24)
        .navigationTitle(navigationTitle)
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
        }
        .trailingToolbarItem {
            trailingNavigationItem()
        }
    }

}

// MARK: - UI定義

private extension HouseworkTemplateItemEditView {

    var navigationTitle: LocalizedStringResource {
        switch mode {
        case .create: .localized("家事を追加")
        case .edit: .localized("家事を編集")
        }
    }

    func inputTitleField() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事の名前", bundle: #bundle)
                .font(with: .headLineS)
            ClearableTextField(
                text: $input.title,
                placeholder: .localized("家事の名前を入力"),
                focus: $isShowingKeyboard
            )
        }
    }

    func inputPointPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("ポイント", bundle: #bundle)
                .font(with: .headLineS)
            PointWheelPickerField(point: $input.point)
                .font(with: .headLineM)
        }
    }

    func inputRecurrenceSelector() -> some View {
        RecurrenceSelector(input: $input.recurrence)
    }

    func trailingNavigationItem() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "paperplane") {
            onTapConfirm()
        }
        .foregroundStyle(.textOnAccent)
        .disabled(!input.canConfirm(mode))
    }

}

#if DEBUG
#Preview("HouseworkTemplateItemEditModal_未入力") {
    HouseworkTemplateItemEditView(
        input: .constant(.initial(UUID())),
        mode: .create
    ) {}
}

#Preview("HouseworkTemplateItemEditModal_入力済み") {
    let beforeInput = TemplateItemEditInput(
        itemId: .init(id: "1"),
        title: "hoge",
        point: 10,
        recurrence: .init(kind: .weekly, weekdays: [.monday, .friday])
    )
    HouseworkTemplateItemEditView(
        input: .constant(beforeInput),
        mode: .edit(before: beforeInput)
    ) {}
}

#Preview("HouseworkTemplateItemEditModal_毎月") {
    let beforeInput = TemplateItemEditInput(
        itemId: .init(id: "1"),
        title: "家賃の振込",
        point: 5,
        recurrence: .init(kind: .monthly, dayOfMonth: 25)
    )
    HouseworkTemplateItemEditView(
        input: .constant(beforeInput),
        mode: .edit(before: beforeInput)
    ) {}
}
#endif
