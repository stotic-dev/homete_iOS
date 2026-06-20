//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @LoadingState var loadingState

    @State var item: HouseworkBoardItem

    @CommonError var commonErrorContent

    var body: some View {
        mainContent()
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
            .fullScreenLoadingIndicator(loadingState)
            .navigationTitle(item.title)
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                NavigationBarButton(label: .delete) {
                    Task {
                        await tappedDeleteHouseworkItem()
                    }
                }
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

}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {

    func tappedDeleteHouseworkItem() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            try await houseworkListStore.remove(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered
            )
            dismiss()
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

    func didChangeItems() {
        guard let targetItem = houseworkListStore.items.item(item.originalItem) else { return }

        withAnimation {
            item = .init(originalItem: targetItem, isRegistered: true)
        }
    }

}

#Preview {
    NavigationStack {
        HouseworkDetailView(
            item: .makeForPreview(
                title: "洗濯",
                point: 10
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
            item: .makeForPreview(
                title: "洗濯",
                point: 10
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(CohabitantStore())
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
