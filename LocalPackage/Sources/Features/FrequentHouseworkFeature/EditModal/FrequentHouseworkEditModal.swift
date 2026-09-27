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

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var input: FrequentHouseworkEditInput
    /// このモーダルから追加したカテゴリ
    /// - Note: 追加直後は購読が届くまで`context`に入らないため、選択肢と名前の重複の判定に足す
    @State var addedCategories: [FrequentHouseworkCustomCategory] = []
    @State var isPresentingCategoryNameAlert = false
    @State var newCategoryName = ""
    @FocusState var isShowingKeyboard: Bool

    let target: FrequentHouseworkEditTarget
    let context: FrequentHouseworkContext
    let onConfirm: (FrequentHouseworkEditInput) -> Void
    /// 新しいカテゴリを作る
    /// - Returns: 作ったカテゴリ。作れる状態にない場合は`nil`
    let onCreateCategory: (String) async throws -> FrequentHouseworkCustomCategory?

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
                .disabled(!validation.isValid)
            }
        }
        .presentationDetents([.medium, .large])
        .alert("新しいカテゴリ", isPresented: $isPresentingCategoryNameAlert) {
            TextField("カテゴリの名前", text: $newCategoryName)
            Button("キャンセル", role: .cancel) {}
            Button("追加") {
                confirmedNewCategory()
            }
            .disabled(!newCategoryNameValidation.isValid)
        } message: {
            Text(newCategoryNameMessage)
        }
        .onAppear {
            onAppear()
        }
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
        .trackScreenView(.frequentHouseworkEdit)
    }

}

extension FrequentHouseworkEditModal {

    /// 対象に応じた初期値で開く
    /// - Note: メンバーごとのイニシャライザ（Previewで入力途中の状態を作るのに使う）を残すため、extensionに置く
    init(
        target: FrequentHouseworkEditTarget,
        context: FrequentHouseworkContext,
        onConfirm: @escaping (FrequentHouseworkEditInput) -> Void,
        onCreateCategory: @escaping (String) async throws -> FrequentHouseworkCustomCategory?
    ) {
        let initialInput: FrequentHouseworkEditInput = switch target {
        case .create:
            .initial

        case let .edit(item):
            .init(item: item, context: context)
        }
        self.init(
            input: initialInput,
            target: target,
            context: context,
            onConfirm: onConfirm,
            onCreateCategory: onCreateCategory
        )
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

    /// このモーダルから追加したカテゴリを含めた、判定と表示に使う値
    var editingContext: FrequentHouseworkContext {
        let knownIds = Set(context.customCategories.map(\.id))
        let pendingCategories = addedCategories.filter { !knownIds.contains($0.id) }
        guard !pendingCategories.isEmpty else { return context }
        return context.replacingCustomCategories(context.customCategories + pendingCategories)
    }

    var validation: FrequentHouseworkContext.TitleValidation {
        input.validation(context: editingContext, editingId: editingId)
    }

    var newCategoryNameValidation: FrequentHouseworkContext.CategoryNameValidation {
        editingContext.validateCategoryName(newCategoryName)
    }

    var newCategoryNameMessage: String {
        switch newCategoryNameValidation {
        case .valid, .emptyName:
            "いつもの家事をまとめる名前を入力してください。"

        case .duplicatedName:
            "同じ名前のカテゴリがあります。"
        }
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

    /// カテゴリの選択肢
    /// - Note: 選択肢と「＋ 新しいカテゴリ」を1つのメニューに並べるため、`Picker`単体ではなく`Menu`で組み立てる
    func inputCategoryPicker() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("カテゴリ")
                .font(with: .headLineS)
            Menu {
                Picker("カテゴリ", selection: $input.categoryId) {
                    ForEach(editingContext.categories) { category in
                        Text(categoryLabel(category))
                            .tag(category.categoryId)
                    }
                }
                .pickerStyle(.inline)
                Divider()
                Button {
                    presentCategoryNameAlert()
                } label: {
                    Label("新しいカテゴリ", systemImage: "plus")
                }
            } label: {
                HStack(spacing: .space4) {
                    Text(selectedCategoryLabel)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
            }
            .tint(.onSurface)
        }
    }

    var selectedCategoryLabel: String {
        let selected = editingContext.categories.first { $0.categoryId == input.categoryId }
        return categoryLabel(selected ?? .uncategorized)
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

    func presentCategoryNameAlert() {
        newCategoryName = ""
        isPresentingCategoryNameAlert = true
    }

    /// カテゴリを追加し、そのまま選択状態にする
    func confirmedNewCategory() {
        let name = newCategoryName
        loadingState.task {
            do {
                guard let createdCategory = try await onCreateCategory(name) else { return }
                addedCategories.append(createdCategory)
                input.categoryId = createdCategory.id
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

}

#if DEBUG
#Preview("FrequentHouseworkEditModal_新規") {
    FrequentHouseworkEditModal(
        target: .create,
        context: .init(),
        onConfirm: { _ in },
        onCreateCategory: { .makeForPreview(id: "new", name: $0) }
    )
}

#Preview("FrequentHouseworkEditModal_編集_名前が重複") {
    let editing = FrequentHouseworkItem.makeForPreview(id: "1", title: "洗濯", point: 20, categoryId: "preset.laundry")
    let other = FrequentHouseworkItem.makeForPreview(id: "2", title: "布団干し", point: 30, categoryId: "preset.laundry")
    FrequentHouseworkEditModal(
        input: .init(title: "布団干し", point: 20, categoryId: "preset.laundry"),
        target: .edit(editing),
        context: .init(items: [editing, other]),
        onConfirm: { _ in },
        onCreateCategory: { .makeForPreview(id: "new", name: $0) }
    )
}
#endif
