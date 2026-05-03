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

    @State private var isShowAnalytics = false

    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                ContributionSummaryComponent.make(onTapAnalytics: { isShowAnalytics = true })
                    .padding(.vertical, .space16)
                // TODO: テンプレート未設定の場合のみ表示する
                PromoteHouseworkTemplateBanner()
                TodayHouseworkListContent()
                TimelineContent()
            }
            .padding(.horizontal, .space16)
        }
        .navigationDestination(isPresented: $isShowAnalytics) {
            ContributionAnalyticsScreen()
        }
    }
}

#Preview {
    RegisteredContent()
        .environment(CohabitantStore())
}
