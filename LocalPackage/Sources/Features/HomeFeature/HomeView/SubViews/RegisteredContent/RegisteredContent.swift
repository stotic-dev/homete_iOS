//
//  RegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import ContributionFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

struct RegisteredContent: View {

    @Environment(\.adComponentResolver) var adComponentResolver
    @Environment(CohabitantStore.self) var cohabiantStore
    @Environment(ContributionStore.self) var contributionStore
    @Environment(HouseworkListStore.self) var houseworkListstore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.routeResolver) var router
    @Environment(\.houseworkTemplateContext.hasTemplate) var hasTemplate

    @State var isShowHouseworkTemplate = false
    @State var isShowPaywall = false
    @State var loadFailure: DomainError?

    @LoadingState var loadingState

    let onRetry: () async -> Void

    var body: some View {
        ZStack {
            if let loadFailure {
                DashboardLoadErrorView(error: loadFailure) {
                    Task { await retry() }
                }
            } else {
                ScrollView {
                    VStack(spacing: .space24) {
                        TodayHouseworkSummaryComponent.make()
                        if !subscriptionStore.isPremium {
                            VStack(spacing: .space8) {
                                adComponentResolver.resolve(.banner(.dashboardTop))
                                    .frame(height: 150)
                                RemoveAdsPromotionLink {
                                    isShowPaywall = true
                                }
                            }
                        }
                        ContributionSummaryComponent.make()
                            .padding(.vertical, .space16)
                            .redacted(reason: loadingState.isLoading ? .placeholder : [])
                        if !hasTemplate {
                            PromoteHouseworkTemplateBanner {
                                isShowHouseworkTemplate = true
                            }
                        }
                    }
                    .padding(.horizontal, .space16)
                }
            }
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
        .onChange(of: contributionStore.loadState) {
            onChangeStoreLoadState()
        }
        .onChange(of: cohabiantStore.loadState) {
            onChangeStoreLoadState()
        }
        .navigationDestination(for: RegisteredContentRoute.self) { route in
            navigationHandler(route)
                .environment(houseworkListstore)
        }
        .fullScreenLoadingIndicator(loadingState)
    }

}

// MARK: UI定義

private extension RegisteredContent {

    @ViewBuilder
    func navigationHandler(_ route: RegisteredContentRoute) -> some View {
        switch route {
        case .incompleteHouseworkList:
            IncompleteHouseworkListView.make()
        }
    }

}

// MARK: プレゼンテーションロジック

private extension RegisteredContent {

    /// 再購読を実行し、完了時点のStoreの状態で表示を組み直す
    ///
    /// - Note: 同じエラーが再発した場合は`loadState`が変化せず`onChange`が発火しないため、
    ///         完了後に明示的に状態を反映する。
    func retry() async {
        loadingState.isLoading = true
        await onRetry()
        onChangeStoreLoadState()
    }

    func onChangeStoreLoadState() {
        // どちらかが失敗していれば、ローディングは解除してエラー表示に倒す
        if case let .failed(error) = contributionStore.loadState {
            loadFailure = error
            loadingState.isLoading = false
            return
        }
        if case let .failed(error) = cohabiantStore.loadState {
            loadFailure = error
            loadingState.isLoading = false
            return
        }

        loadFailure = nil
        // Storeの初回ロード完了まで、ローディング画面を表示する
        loadingState.isLoading = contributionStore.loadState != .loaded || cohabiantStore.loadState != .loaded
    }

}

#if DEBUG
#Preview {
    RegisteredContent(onRetry: {})
        .environment(ContributionStore())
        .environment(CohabitantStore())
        .environment(HouseworkListStore())
        .environment(SubscriptionStore())
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
        .setupEnvironmentForPreview()
}

#Preview("プレミアム登録済み_広告非表示") {
    RegisteredContent(onRetry: {})
        .environment(ContributionStore())
        .environment(CohabitantStore())
        .environment(HouseworkListStore())
        .environment(SubscriptionStore(entitlementInfo: .init(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )))
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
        .setupEnvironmentForPreview()
}
#endif
