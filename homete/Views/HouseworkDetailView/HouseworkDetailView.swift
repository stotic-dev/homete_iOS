//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import SwiftUI

struct HouseworkDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @LoadingState var loadingState
    
    @State var item: HouseworkItem
    
    @CommonError var commonErrorContent
    
    var body: some View {
        mainContent()
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
            .fullScreenLoadingIndicator(loadingState)
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
            HouseworkDetailItemListContent(
                cohabitantMemberList: cohabitantStore.members,
                item: item
            )
            Spacer()
            HouseworkDetailActionContent(
                isLoading: $loadingState.isLoading,
                commonErrorContent: $commonErrorContent,
                account: account,
                item: item
            )
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
                metaData: .init(indexedDate: .init(value: "0001/01/01"), expiredAt: .distantFuture)
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(CohabitantStore())
}

#Preview("HouseworkDetailView_通信中") {
    NavigationStack {
        HouseworkDetailView(
            loadingState: .init(store: .init(isLoading: true)),
            item: .init(
                id: "",
                title: "洗濯",
                point: 10,
                metaData: .init(indexedDate: .init(value: "0001/01/01"), expiredAt: .distantFuture)
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(CohabitantStore())
}
