//
//  HouseworkTemplateItemEditModal.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkTemplateItemEditModalScreen: View {

    @State var input: TemplateItemEditInput = .initial(UUID())
    @FocusState var isShowingKeyboard: Bool

    let mode: EditMode
    let onConfirm: (TemplateItemEditInput) -> Void

    var body: some View {
        HouseworkTemplateItemEditModal(
            input: $input,
            isShowingKeyboard: _isShowingKeyboard,
            mode: mode,
            onConfirm: onConfirm
        )
        .background {
            if isShowingKeyboard {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tappedBackgroundArea()
                    }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            onAppear()
        }
    }

}

// MAKR: - プレゼンテーションロジック

private extension HouseworkTemplateItemEditModalScreen {

    func onAppear() {
        if case let .edit(before) = mode {
            // 編集時は元の入力値を表示しておく
            input = before
        } else {
            // 新規作成時はテキストフィールドを最初から表示しておく
            isShowingKeyboard = true
        }
    }

    func tappedBackgroundArea() {
        isShowingKeyboard = false
    }

}

/// 家事追加・編集モーダル（ハーフモーダル / 新規・編集兼用）。
private struct HouseworkTemplateItemEditModal: View {

    @Environment(\.dismiss) var dismiss

    @Binding var input: TemplateItemEditInput
    @FocusState var isShowingKeyboard: Bool

    let mode: EditMode
    let onConfirm: (TemplateItemEditInput) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .space16) {
                inputTitleField()
                inputPointSlider()
                inputDaysSelector()
                Spacer()
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
            .navigationTitle(navigationTitle)
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    dismiss()
                }
            }
            .trailingToolbarItem {
                trailingNavigationItem()
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkTemplateItemEditModal {

    var navigationTitle: String {
        switch mode {
        case .create: "家事を追加"
        case .edit: "家事を編集"
        }
    }

    func inputTitleField() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事の名前")
                .font(with: .headLineS)
            ClearableTextField(
                text: $input.title,
                placeholder: "家事の名前を入力",
                focus: $isShowingKeyboard
            )
        }
    }

    func inputPointSlider() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("ポイント")
                .font(with: .headLineS)
            HStack(spacing: .space16) {
                Slider(value: $input.point, in: 1 ... 100, step: 1)
                Text(Int(input.point).formatted())
                    .font(with: .headLineM)
                    .frame(minWidth: 40, alignment: .trailing)
            }
        }
    }

    func inputDaysSelector() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("曜日")
                .font(with: .headLineS)
            WeekdaySelector(selection: $input.days)
        }
    }

    func trailingNavigationItem() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "paperplane") {
            tappedConfirmButton()
        }
        .foregroundStyle(.onPrimary1)
        .disabled(!input.canConfirm(mode))
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateItemEditModal {

    func tappedConfirmButton() {
        onConfirm(input)
        dismiss()
    }

}

#if DEBUG
#Preview("HouseworkTemplateItemEditModal_未入力") {
    HouseworkTemplateItemEditModal(
        input: .constant(.initial(UUID())),
        mode: .create
    ) { _ in }
}

#Preview("HouseworkTemplateItemEditModal_入力済み") {
    let beforeInput = TemplateItemEditInput(
        itemId: .init(id: "1"),
        title: "hoge",
        point: 10,
        days: [.monday, .friday]
    )
    HouseworkTemplateItemEditModal(
        input: .constant(beforeInput),
        mode: .edit(before: beforeInput)
    ) { _ in }
}
#endif
