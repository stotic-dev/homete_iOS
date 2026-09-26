//
//  HouseworkDetailActionContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkDetailActionContent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.routeResolver) var router
    @Environment(\.loginContext.cohabitantId) var cohabitantId
    @State var isPresentedThanksView = false
    @State var isPresentedCompleteSheet = false

    @Binding var isLoading: Bool
    @Binding var commonErrorContent: DomainErrorAlertContent

    let account: Account
    let item: HouseworkBoardItem

    var body: some View {
        VStack(spacing: .space16) {
            switch item.state {
            case .incomplete:
                completeButton()
            case .completed:
                if item.canSendThanks(ownUserId: account.id) {
                    sendThanksButton()
                }
                undoChangeStateButton()
            case .notTodo:
                EmptyView()
            }
        }
        .disabled(isLoading)
        .sheet(isPresented: $isPresentedCompleteSheet) {
            HouseworkCompleteSheet(item: item, step: .detail)
        }
        .sheet(isPresented: $isPresentedThanksView) {
            HouseworkThanksView(item: item)
        }
    }

}

private extension HouseworkDetailActionContent {

    func completeButton() -> some View {
        Button {
            isPresentedCompleteSheet = true
        } label: {
            Label("完了にする", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
    }

    func undoChangeStateButton() -> some View {
        Button {
            isLoading = true
            Task {
                await tappedUndoStateButton()
                isLoading = false
            }
        } label: {
            Label("未完了に戻す", systemImage: "arrow.uturn.backward")
                .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
    }

    func sendThanksButton() -> some View {
        Button {
            isPresentedThanksView = true
        } label: {
            Label("ありがとうを伝える", systemImage: "hands.clap.fill")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
    }

}

// プレゼンテーションロジック

private extension HouseworkDetailActionContent {

    func tappedUndoStateButton() async {
        guard let cohabitantId else { return }

        do {
            try await houseworkListStore.returnToIncomplete(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                step: .detail
            )
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

}

#if DEBUG
#Preview("HouseworkDetailActionContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "", userName: "", fcmToken: nil, cohabitantId: nil),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1))
        )
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_完了_実施者アカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "dummy", userName: "", fcmToken: nil, cohabitantId: nil),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "dummy"
        )
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_完了_実施者以外のアカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "ownAccount", userName: "", fcmToken: nil, cohabitantId: nil),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "executorAccount"
        )
    )
    .environment(HouseworkListStore())
}
#endif
