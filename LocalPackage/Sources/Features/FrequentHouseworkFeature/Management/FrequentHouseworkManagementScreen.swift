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
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.routeResolver) var router
    @Environment(FrequentHouseworkStore.self) var store: FrequentHouseworkStore?
    @Environment(SubscriptionStore.self) var subscriptionStore

    @LoadingState var loadingState
    @CommonError var commonErrorContent

    @State var editTarget: FrequentHouseworkEditTarget?
    @State var isPresentingLimitAlert = false
    @State var isShowPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            FrequentHouseworkManagementView(
                loadState: store?.loadState ?? .loading,
                sections: context.sections,
                unusableItemIds: limitPolicy.unusableItemIds(in: context),
                limitStatus: limitStatus,
                onTapClose: { dismiss() },
                onTapAdd: { tappedAddButton() },
                onTapItem: { item in editTarget = .edit(item) },
                onDelete: { item in deleteItem(item) },
                onMove: { orderedIds in reorderItems(orderedIds) },
                onTapUpgrade: { showPaywall() },
                onRetry: { retry() }
            )
        }
        .sheet(item: $editTarget) { target in
            FrequentHouseworkEditModal(target: target, context: context) { input in
                confirmedEdit(input, target: target)
            }
        }
        .alert(
            "無料プランでは、いつもの家事を\(FrequentHouseworkLimitPolicy.freeLimit)件まで登録できます",
            isPresented: $isPresentingLimitAlert
        ) {
            Button("プレミアムプランを見る") {
                showPaywall()
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("プレミアムプランにすると、件数を気にせず登録できます。")
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

// MARK: - 表示内容

private extension FrequentHouseworkManagementScreen {

    var limitPolicy: FrequentHouseworkLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var limitStatus: FrequentHouseworkLimitStatus? {
        limitPolicy.limit.map { .init(count: context.items.count, limit: $0) }
    }

}

// MARK: - プレゼンテーションロジック

private extension FrequentHouseworkManagementScreen {

    func tappedAddButton() {
        // 読み込み前の空の一覧で判定すると、件数上限や名前の重複をすり抜けてしまう
        guard store?.loadState == .loaded else { return }
        guard limitPolicy.canAdd(1, currentCount: context.items.count) else {
            store?.logLimitReached(step: .management)
            isPresentingLimitAlert = true
            return
        }
        editTarget = .create
    }

    func confirmedEdit(_ input: FrequentHouseworkEditInput, target: FrequentHouseworkEditTarget) {
        guard let store, let cohabitantId else { return }
        loadingState.task {
            do {
                switch target {
                case .create:
                    try await store.add(
                        [input.domainInput],
                        limitPolicy: limitPolicy,
                        step: .management,
                        cohabitantId: cohabitantId
                    )

                case let .edit(item):
                    try await store.update(
                        itemId: item.id,
                        input: input.domainInput,
                        cohabitantId: cohabitantId
                    )
                }
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
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
