//
//  RegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeUI
import SwiftUI

struct RegisteredContent: View {

    @Environment(\.routeResolver) var router
    @State var isShowHouseworkTemplate = false

    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                HouseworkPointDashboardContent(monthlyPoint: 0, thanksPoint: 0)
                    .padding(.vertical, .space16)
                // TODO: テンプレート未設定の場合のみ表示する
                PromoteHouseworkTemplateBanner {
                    isShowHouseworkTemplate = true
                }
                TodayHouseworkListContent()
                TimelineContent()
            }
            .padding(.horizontal, .space16)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
    }
}

#Preview {
    RegisteredContent()
}
