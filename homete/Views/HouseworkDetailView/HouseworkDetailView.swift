//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import SwiftUI

struct HouseworkDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(HouseworkListStore.self) var houseworkListStore
    
    @State var isLoading = false
    @CommonError var commonErrorContent
    
    let item: HouseworkItem
    
    var body: some View {
        ZStack {
            mainContent()
                .padding(.horizontal, DesignSystem.Space.space16)
                .padding(.bottom, DesignSystem.Space.space24)
            LoadingIndicator()
                .opacity(isLoading ? 1 : 0)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            trailingNavigationBarContent()
        }
        .commonError(content: $commonErrorContent)
    }
}

private extension HouseworkDetailView {
    
    func mainContent() -> some View {
        VStack(spacing: .zero) {
            detailItemList()
            Spacer()
            Button {
                Task {
                    await tappedRequestConfirmButton()
                }
            } label: {
                Label("確認してもらう", image: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }
    
    func detailItemList() -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.space24) {
            HouseworkDetailItemRow(title: "実施予定日付") {
                Text(item.formattedIndexedDate)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
            }
            HouseworkDetailItemRow(title: "ステータス") {
                Text(item.state.segmentTitle)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
            }
            HouseworkDetailItemRow(title: "ポイント") {
                PointLabel(point: item.point)
            }
        }
    }
    
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
    
    func tappedRequestConfirmButton() async {
        
        isLoading = true
        
        do {
            try await houseworkListStore.requestReview(id: item.id, indexedDate: item.indexedDate)
        }
        catch {
            commonErrorContent = .init(error: error)
        }
        
        isLoading = false
    }
    
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
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
}

#Preview("HouseworkDetailView_通信中") {
    NavigationStack {
        HouseworkDetailView(
            isLoading: true,
            item: .init(
                id: "",
                title: "洗濯",
                point: 10,
                metaData: .init(indexedDate: .distantPast, expiredAt: .distantFuture)
            )
        )
    }
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue
    ))
}
