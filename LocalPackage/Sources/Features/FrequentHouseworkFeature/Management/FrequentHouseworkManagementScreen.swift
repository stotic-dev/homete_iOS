//
//  FrequentHouseworkManagementScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事の管理画面
/// - Note: ホームの「おすすめの設定」・設定画面・選ぶ部品の「管理」から、`AppRoute.frequentHouseworkManagement`で開く
public struct FrequentHouseworkManagementScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.frequentHouseworkContext) var context
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.routeResolver) var router
    @Environment(FrequentHouseworkStore.self) var store: FrequentHouseworkStore?
    @Environment(SubscriptionStore.self) var subscriptionStore

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var navigationPath = AppNavigationPath<FrequentHouseworkManagementRoute>()
    @State var editTarget: FrequentHouseworkEditTarget?
    @State var isPresentingImport = false
    @State var isPresentingLimitAlert = false
    @State var isShowPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            FrequentHouseworkManagementView(
                loadState: store?.loadState ?? .loading,
                sections: context.sections,
                unusableItemIds: limitPolicy.unusableItemIds(in: context),
                limitStatus: limitStatus,
                onTapClose: { dismiss() },
                onTapAdd: { tappedAddButton() },
                onTapManageCategories: { navigationPath.push(.categoryManagement) },
                onTapImport: canImportFromTemplate ? { isPresentingImport = true } : nil,
                onTapItem: { item in editTarget = .edit(item) },
                onDelete: { item in deleteItem(item) },
                onMove: { orderedIds in reorderItems(orderedIds) },
                onTapUpgrade: { showPaywall() },
                onRetry: { retry() }
            )
            .navigationDestination(for: FrequentHouseworkManagementRoute.self) { route in
                navigationHandler(route)
            }
        }
        .sheet(item: $editTarget) { target in
            FrequentHouseworkEditModal(
                target: target,
                context: context,
                onConfirm: { input in confirmedEdit(input, target: target) },
                onCreateCategory: { name in try await createCategory(name: name) }
            )
        }
        .sheet(isPresented: $isPresentingImport) {
            FrequentHouseworkImportScreen()
        }
        .alert(
            .localized("無料プランでは、いつもの家事を\(FrequentHouseworkLimitPolicy.freeLimit)件まで登録できます"),
            isPresented: $isPresentingLimitAlert
        ) {
            Button(.localized("プレミアムプランを見る")) {
                showPaywall()
            }
            Button(.localized("閉じる"), role: .cancel) {}
        } message: {
            Text("プレミアムプランにすると、件数を気にせず登録できます。", bundle: #bundle)
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
    }

}

// MARK: - 画面遷移

private extension FrequentHouseworkManagementScreen {

    @ViewBuilder
    func navigationHandler(_ route: FrequentHouseworkManagementRoute) -> some View {
        switch route {
        case .categoryManagement:
            FrequentHouseworkCategoryScreen()
        }
    }

}

// MARK: - 表示内容

private extension FrequentHouseworkManagementScreen {

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var memoLimitPolicy: HouseworkMemoLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var limitStatus: FrequentHouseworkLimitStatus? {
        .init(policy: limitPolicy, count: context.items.count)
    }

    /// テンプレートから取り込めるか（取り込む家事がないシートを開かせないため）
    var canImportFromTemplate: Bool {
        templateContext.houseworkTemplate.contains { !$0.items.isEmpty }
    }

}

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkManagementScreen {

    func tappedAddButton() {
        // 読み込み前の空の一覧で判定すると、件数上限や名前の重複をすり抜けてしまう
        guard store?.loadState == .loaded else { return }
        guard !limitPolicy.isLimitReached(currentCount: context.items.count) else {
            store?.logLimitReached(step: .management)
            isPresentingLimitAlert = true
            return
        }
        editTarget = .create
    }

    func confirmedEdit(_ input: FrequentHouseworkEditInput, target: FrequentHouseworkEditTarget) {
        // モーダルを開いている間にリスナーが止まった場合は、古いデータで判定した内容を書き込まない
        guard let store, store.loadState == .loaded, let cohabitantId else { return }
        loadingState.task {
            do {
                switch target {
                case .create:
                    try await store.add(
                        [input.domainInput],
                        limitPolicy: limitPolicy,
                        memoLimitPolicy: memoLimitPolicy,
                        step: .management,
                        cohabitantId: cohabitantId
                    )

                case let .edit(item):
                    try await store.update(
                        itemId: item.id,
                        input: input.domainInput,
                        memoLimitPolicy: memoLimitPolicy,
                        cohabitantId: cohabitantId
                    )
                }
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    /// 編集モーダルから開いた「＋ 新しいカテゴリ」でカテゴリを追加する
    /// - Returns: 追加したカテゴリ。読み込み前・リスナーが止まった後は名前の重複を判定できないため`nil`
    func createCategory(name: String) async throws -> FrequentHouseworkCustomCategory? {
        guard let store, store.loadState == .loaded, let cohabitantId else { return nil }
        return try await store.addCategory(name: name, cohabitantId: cohabitantId)
    }

    func deleteItem(_ item: FrequentHouseworkItem) {
        guard let store, let cohabitantId else { return }
        Task {
            do {
                try await store.delete(itemId: item.id, cohabitantId: cohabitantId)
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    func reorderItems(_ orderedIds: [String]) {
        guard let store, let cohabitantId else { return }
        Task {
            do {
                try await store.reorderItems(orderedIds, cohabitantId: cohabitantId)
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    func retry() {
        guard let store, let cohabitantId else { return }
        Task {
            await store.startObserving(cohabitantId: cohabitantId)
        }
    }

    func showPaywall() {
        analyticsClient.log(.paywall(.shown(step: .frequentHouseworkLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(
            step: .frequentHouseworkLimit,
            isPremium: subscriptionStore.isPremium
        )))
    }

}
