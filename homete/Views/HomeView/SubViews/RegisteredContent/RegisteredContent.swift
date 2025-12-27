//
//  RegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct RegisteredContent: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                HouseworkPointDashboardContent(monthlyPoint: 0, thanksPoint: 0)
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

#Preview {
    RegisteredContent()
}
