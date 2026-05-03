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

    @Environment(ContributionStore.self) var contributionStore
    
    @State private var isShowAnalytics = false
    @State var members: CohabitantMemberList = .init(value: [])

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: .space24) {
                    ContributionSummaryComponent.make()
                        .padding(.vertical, .space16)
                    // TODO: テンプレート未設定の場合のみ表示する
                    PromoteHouseworkTemplateBanner()
                    TodayHouseworkListContent()
                    TimelineContent()
                }
                .padding(.horizontal, .space16)
            }
        }
    }
}

#Preview {
    RegisteredContent()
        .environment(ContributionStore())
        .environment(CohabitantStore())
        .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
        .setupEnvironmentForPreview()
}
