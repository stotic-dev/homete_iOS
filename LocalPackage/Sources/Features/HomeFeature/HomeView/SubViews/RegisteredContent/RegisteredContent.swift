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
    @Environment(HouseworkListStore.self) var hoseworkListstore
    @Environment(\.routeResolver) var router

    @State var isShowHouseworkTemplate = false

    @LoadingState var loadingState

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: .space24) {
                    TodayHouseworkSummaryComponent.make()
                    adComponentResolver.resolve(.banner(.dashboardTop))
                        .frame(height: 150)
                    ContributionSummaryComponent.make()
                        .padding(.vertical, .space16)
                        .redacted(reason: loadingState.isLoading ? .placeholder : [])
                    // TODO: テンプレート未設定の場合のみ表示する
                    PromoteHouseworkTemplateBanner {
                        isShowHouseworkTemplate = true
                    }
                }
                .padding(.horizontal, .space16)
            }
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .onChange(of: contributionStore.isInitialLoaded) {
            onChangeStoreInitialLoadedStatus()
        }
        .onChange(of: cohabiantStore.isInitialLoaded) {
            onChangeStoreInitialLoadedStatus()
        }
        .navigationDestination(for: RegisteredContentRoute.self) { route in
            navigationHandler(route)
                .environment(hoseworkListstore)
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

    func onChangeStoreInitialLoadedStatus() {
        // Storeの初回ロード完了まで、ローディング画面を表示する
        loadingState.isLoading = !contributionStore.isInitialLoaded || !cohabiantStore.isInitialLoaded
    }

}

#if DEBUG
#Preview {
    RegisteredContent()
        .environment(ContributionStore())
        .environment(CohabitantStore())
        .environment(HouseworkListStore())
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
        .setupEnvironmentForPreview()
}
#endif
