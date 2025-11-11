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
    
    @State var isPresentingOperationErrorAlert = false
    
    let item: HouseworkItem
    
    var body: some View {
        mainContent()
            .padding(.horizontal, DesignSystem.Space.space16)
            .padding(.bottom, DesignSystem.Space.space24)
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingNavigationBarContent()
            }
    }
}

private extension HouseworkDetailView {
    
    func mainContent() -> some View {
        VStack(spacing: DesignSystem.Space.space24) {
            detailItemRow("実施予定日付") {
                Text(item.formattedIndexedDate)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
            }
            detailItemRow("ステータス") {
                Text(item.state.segmentTitle)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
            }
            detailItemRow("ポイント") {
                PointLabel(point: item.point)
            }
            Spacer()
            Button {
                // TODO: 承認依頼
            } label: {
                Label("確認してもらう", image: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }
    
    func detailItemRow(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
            Text(title)
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
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
    
    func tappedRequestConfirmButton() {
        Task {
            do {
                try await houseworkListStore.requestReview(id: item.id, indexedDate: item.indexedDate)
            }
            catch {
                // TODO: エラーハンドリング
            }
        }
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
    .environment(HouseworkListStore(houseworkClient: .previewValue))
}
