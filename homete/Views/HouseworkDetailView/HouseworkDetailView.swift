//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import SwiftUI

struct HouseworkDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let item: HouseworkItem
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
            Button {
                // TODO: 承認依頼
            } label: {
                Label("確認してもらう", image: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .padding(.bottom, DesignSystem.Space.space24)
        .toolbar {
            trailingNavigationBarContent()
        }
    }
}

private extension HouseworkDetailView {
    
    func trailingNavigationBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationBarButton(label: .delete) {
                tappedDeleteHouseworkItem()
            }
        }
    }
}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {
    
    func tappedDeleteHouseworkItem() {
        // TODO: 家事削除
        dismiss()
    }
}

#Preview {
    NavigationStack {
        HouseworkDetailView(
            item: .init(
                id: "",
                title: "洗濯",
                point: 10,
                metaData: .init(indexedDate: .distantPast, expiredAt: .distantFuture)
            )
        )
    }
}
