//
//  RegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import ContributionFeature
import HometeDomain
import HometeUI
import SwiftUI

struct RegisteredContent: View {

    @Environment(CohabitantStore.self) var cohabiantStore
    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.routeResolver) var router

    @State var isShowHouseworkTemplate = false

    @LoadingState var loadingState

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: .space24) {
                    ContributionSummaryComponent.make()
                        .padding(.vertical, .space16)
                        .redacted(reason: loadingState.isLoading ? .placeholder : [])
                    // TODO: テンプレート未設定の場合のみ表示する
                    PromoteHouseworkTemplateBanner {
                        isShowHouseworkTemplate = true
                    }
                    TodayHouseworkListContent()
                    TimelineContent()
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
        .fullScreenLoadingIndicator(loadingState)
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
            .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
            .setupEnvironmentForPreview()
    }
#endif
