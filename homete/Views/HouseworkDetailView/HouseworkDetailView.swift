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
    @Environment(AccountStore.self) var accountStore
    
    @State var isLoading = false
    @State var item: HouseworkItem
    
    @CommonError var commonErrorContent
    
    var body: some View {
        mainContent()
            .padding(.horizontal, DesignSystem.Space.space16)
            .padding(.bottom, DesignSystem.Space.space24)
            .fullScreenLoadingIndicator(isLoading)
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                trailingNavigationBarContent()
            }
            .commonError(content: $commonErrorContent)
            .onChange(of: houseworkListStore.items) {
                didChangeItems()
            }
    }
}

private extension HouseworkDetailView {
    
    func mainContent() -> some View {
        VStack(spacing: .zero) {
            detailItemList()
            Spacer()
            HouseworkDetailActionContent(
                isLoading: $isLoading,
                commonErrorContent: $commonErrorContent,
                account: accountStore.account,
                item: item
            )
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
                Task {
                    await tappedDeleteHouseworkItem()
                }
            }
        }
    }
}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {
    
    func tappedDeleteHouseworkItem() async {
        
        do {
            
            try await houseworkListStore.remove(item)
            dismiss()
        }
        catch {
            
            commonErrorContent = .init(error: error)
        }
    }
    
    func didChangeItems() {
        
        guard let targetItem = houseworkListStore.items.item(item.id, item.indexedDate) else { return }
        
        withAnimation {
            
            item = targetItem
        }
    }
}

#Preview {
    NavigationStack {
        HouseworkDetailView(
            item: .init(
                id: "",
                title: "洗濯",
                point: 10,
                metaData: .init(indexedDate: .init(.distantPast), expiredAt: .distantFuture)
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(AccountStore(appDependencies: .previewValue))
}

#Preview("HouseworkDetailView_通信中") {
    NavigationStack {
        HouseworkDetailView(
            isLoading: true,
            item: .init(
                id: "",
                title: "洗濯",
                point: 10,
                metaData: .init(indexedDate: .init(.distantPast), expiredAt: .distantFuture)
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(AccountStore(appDependencies: .previewValue))
}
