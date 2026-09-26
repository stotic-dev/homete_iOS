//
//  FrequentHouseworkEditModal.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事の追加・編集モーダル（ハーフモーダル / 新規・編集兼用）
struct FrequentHouseworkEditModal: View {

    @Environment(\.dismiss) var dismiss

    @State var input: FrequentHouseworkEditInput
    @FocusState var isShowingKeyboard: Bool

    let target: FrequentHouseworkEditTarget
    let context: FrequentHouseworkContext
    let onConfirm: (FrequentHouseworkEditInput) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .space16) {
                inputTitleField()
                inputPointPicker()
                inputCategoryPicker()
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
                NavigationBarPrimaryActionButton(systemImage: "checkmark") {
                    tappedConfirmButton()
                }
                .disabled(validation != .valid)
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            onAppear()
        }
        .trackScreenView(.frequentHouseworkEdit)
    }

}

extension FrequentHouseworkEditModal {

    /// 対象に応じた初期値で開く
    /// - Note: メンバーごとのイニシャライザ（Previewで入力途中の状態を作るのに使う）を残すため、extensionに置く
    init(
        target: FrequentHouseworkEditTarget,
        context: FrequentHouseworkContext,
        onConfirm: @escaping (FrequentHouseworkEditInput) -> Void
    ) {
        let initialInput: FrequentHouseworkEditInput = switch target {
        case .create:
            .initial

        case let .edit(item):
            .init(item: item, context: context)
        }
        self.init(input: initialInput, target: target, context: context, onConfirm: onConfirm)
    }

}

// MARK: - UI定義

private extension FrequentHouseworkEditModal {

    var navigationTitle: String {
        switch target {
        case .create:
            "いつもの家事を追加"

        case .edit:
            "いつもの家事を編集"
        }
    }

    var validation: FrequentHouseworkEditInput.Validation {
        input.validation(context: context, editingId: editingId)
    }

    var editingId: String? {
        switch target {
        case .create:
            nil

        case let .edit(item):
            item.id
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
            if validation == .duplicatedTitle {
                Text("同じ名前のいつもの家事があります")
                    .font(with: .caption)
                    .foregroundStyle(.destructive)
            }
        }
    }

    func inputPointPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("ポイント")
                .font(with: .headLineS)
            PointWheelPickerField(point: $input.point)
                .font(with: .headLineM)
        }
    }

    func inputCategoryPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("カテゴリ")
                .font(with: .headLineS)
            Picker("カテゴリ", selection: $input.categoryId) {
                ForEach(context.categories) { category in
                    Text(categoryLabel(category))
                        .tag(category.categoryId)
                }
            }
            .pickerStyle(.menu)
            .tint(.onSurface)
        }
    }

    func categoryLabel(_ category: FrequentHouseworkCategory) -> String {
        switch category {
        case .uncategorized:
            "\(category.name)（未設定）"

        case .preset, .custom:
            category.name
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkEditModal {

    func onAppear() {
        // 新規追加時はすぐに入力できるようにキーボードを出しておく
        if case .create = target {
            isShowingKeyboard = true
        }
    }

    func tappedConfirmButton() {
        onConfirm(input)
        dismiss()
    }

}

#if DEBUG
#Preview("FrequentHouseworkEditModal_新規") {
    FrequentHouseworkEditModal(
        target: .create,
        context: .init(),
        onConfirm: { _ in }
    )
}

#Preview("FrequentHouseworkEditModal_編集_名前が重複") {
    let editing = FrequentHouseworkItem.makeForPreview(id: "1", title: "洗濯", point: 20, categoryId: "preset.laundry")
    let other = FrequentHouseworkItem.makeForPreview(id: "2", title: "布団干し", point: 30, categoryId: "preset.laundry")
    FrequentHouseworkEditModal(
        input: .init(title: "布団干し", point: 20, categoryId: "preset.laundry"),
        target: .edit(editing),
        context: .init(items: [editing, other]),
        onConfirm: { _ in }
    )
}
#endif
