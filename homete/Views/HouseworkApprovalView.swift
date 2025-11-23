//
//  HouseworkApprovalView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

struct HouseworkApprovalView: View {
    @Environment(\.dismiss) var dismiss
    
    let item: HouseworkItem
    
    var body: some View {
        AppNavigationPath { _ in
            ScrollView {
                VStack(spacing: DesignSystem.Space.space24) {
                    VStack(spacing: DesignSystem.Space.space8) {
                        Text("完了報告")
                            .font(with: .headLineM)
                        Text("〇〇さんから\n「\(item.title)」の完了報告が届きました！")
                            .multilineTextAlignment(.center)
                            .font(with: .body)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("家事の確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                navigationLeadingItem()
            }
        }
    }
}

private extension HouseworkApprovalView {
    
    func navigationLeadingItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationBarButton(label: .close) {
                dismiss()
            }
        }
    }
}

#Preview {
    HouseworkApprovalView(item: .init(
        id: "",
        title: "洗濯",
        point: 10,
        metaData: .init(indexedDate: .distantPast, expiredAt: .distantPast)
    ))
}
