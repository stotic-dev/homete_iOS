//
//  FrequentHouseworkEditModal.swift
//  LocalPackage
//

import FrequentHouseworkFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事の追加・編集モーダル（ハーフモーダル / 新規・編集兼用）
struct FrequentHouseworkEditModal: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.routeResolver) var router
    @Environment(SubscriptionStore.self) var subscriptionStore

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var input: FrequentHouseworkEditInput
    /// このモーダルから追加したカテゴリ
    /// - Note: 追加直後は購読が届くまで`context`に入らないため、選択肢と名前の重複の判定に足す
    @State var addedCategories: [FrequentHouseworkCustomCategory] = []
    @State var isPresentedMemoEditSheet = false

    let target: FrequentHouseworkEditTarget
    let context: FrequentHouseworkContext
    let onConfirm: (FrequentHouseworkEditInput) -> Void
    /// 新しいカテゴリを作る
    /// - Returns: 作ったカテゴリ。作れる状態にない場合は`nil`
    let onCreateCategory: (String) async throws -> FrequentHouseworkCustomCategory?

    var body: some View {
        NavigationStack {
            FrequentHouseworkEditView(
                input: $input,
                target: target,
                context: context,
                addedCategories: addedCategories,
                onTapClose: { dismiss() },
                onTapConfirm: { tappedConfirmButton() },
                onTapMemo: { isPresentedMemoEditSheet = true },
                onConfirmNewCategory: { confirmedNewCategory(name: $0) }
            )
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isPresentedMemoEditSheet) {
            // すべて消したメモも空のまま残す。旧バージョンのアプリによる上書きを防ぐため（ADR-0034）
            HouseworkMemoEditScreen(memo: input.memo, isPremium: subscriptionStore.isPremium) { memo in
                input.memo = memo
            } paywall: {
                router.resolve(.paywall(step: .houseworkMemoLimit))
            }
            .trackScreenView(.houseworkMemoEdit)
        }
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
        .trackScreenView(.frequentHouseworkEdit)
    }

}

extension FrequentHouseworkEditModal {

    /// 対象に応じた初期値で開く
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

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkEditModal {

    func tappedConfirmButton() {
        onConfirm(input)
        dismiss()
    }

    /// カテゴリを追加し、そのまま選択状態にする
    func confirmedNewCategory(name: String) {
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
