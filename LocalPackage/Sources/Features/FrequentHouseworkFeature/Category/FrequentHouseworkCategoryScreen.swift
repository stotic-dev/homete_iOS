//
//  FrequentHouseworkCategoryScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事のカテゴリ管理画面（管理画面からpushで開く）
struct FrequentHouseworkCategoryScreen: View {

    @Environment(\.frequentHouseworkContext) var context
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(FrequentHouseworkStore.self) var store: FrequentHouseworkStore?

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var editTarget: FrequentHouseworkCategoryEditTarget?
    @State var editingName = ""
    @State var deleteTarget: FrequentHouseworkCustomCategory?

    var body: some View {
        FrequentHouseworkCategoryView(
            customCategories: context.sortedCustomCategories,
            onTapAdd: { presentEdit(.create) },
            onTapCategory: { category in presentEdit(.rename(category)) },
            onDelete: { category in deleteTarget = category },
            onMove: { orderedIds in reorderCategories(orderedIds) }
        )
        .alert(
            editTarget?.title ?? "",
            isPresented: isPresentingEdit,
            presenting: editTarget
        ) { target in
            TextField(.localized("カテゴリの名前"), text: $editingName)
            Button(.localized("キャンセル"), role: .cancel) {}
            Button(target.confirmLabel) {
                confirmedEdit(target)
            }
            .disabled(!nameValidation.isValid)
        } message: { _ in
            Text(nameValidationMessage)
        }
        .alert(
            .localized("このカテゴリを削除しますか？"),
            isPresented: isPresentingDelete,
            presenting: deleteTarget
        ) { category in
            Button(.localized("削除"), role: .destructive) {
                deleteCategory(category)
            }
            Button(.localized("キャンセル"), role: .cancel) {}
        } message: { _ in
            Text("このカテゴリのいつもの家事は「その他」に表示されます。", bundle: #bundle)
        }
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
    }

}

// MARK: - 表示内容

private extension FrequentHouseworkCategoryScreen {

    /// 名前を入力するアラートの表示状態
    /// - Note: `alert(_:isPresented:presenting:)`は`Bool`を求めるため、対象の有無をそのまま表示状態として扱う
    var isPresentingEdit: Binding<Bool> {
        .init(
            get: { editTarget != nil },
            set: { isPresenting in
                if !isPresenting {
                    editTarget = nil
                }
            }
        )
    }

    /// 削除を確認するアラートの表示状態
    var isPresentingDelete: Binding<Bool> {
        .init(
            get: { deleteTarget != nil },
            set: { isPresenting in
                if !isPresenting {
                    deleteTarget = nil
                }
            }
        )
    }

    /// 入力中の名前が決定できるかどうか
    var nameValidation: FrequentHouseworkContext.CategoryNameValidation {
        context.validateCategoryName(editingName, excludingId: editTarget?.editingId)
    }

    var nameValidationMessage: LocalizedStringResource {
        switch nameValidation {
        case .valid, .emptyName:
            .localized("いつもの家事をまとめる名前を入力してください。")

        case .duplicatedName:
            .localized("同じ名前のカテゴリがあります。")
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkCategoryScreen {

    func presentEdit(_ target: FrequentHouseworkCategoryEditTarget) {
        editingName = target.initialName
        editTarget = target
    }

    func confirmedEdit(_ target: FrequentHouseworkCategoryEditTarget) {
        // 読み込み前・リスナーが止まった後の一覧で判定すると、名前の重複をすり抜けてしまう
        guard let store, store.loadState == .loaded, let cohabitantId else { return }
        let name = editingName
        loadingState.task {
            do {
                switch target {
                case .create:
                    try await store.addCategory(name: name, cohabitantId: cohabitantId)

                case let .rename(category):
                    try await store.renameCategory(id: category.id, name: name, cohabitantId: cohabitantId)
                }
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    func deleteCategory(_ category: FrequentHouseworkCustomCategory) {
        guard let store, let cohabitantId else { return }
        Task {
            do {
                try await store.deleteCategory(id: category.id, cohabitantId: cohabitantId)
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    func reorderCategories(_ orderedIds: [String]) {
        guard let store, let cohabitantId else { return }
        Task {
            do {
                try await store.reorderCategories(orderedIds, cohabitantId: cohabitantId)
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

}
