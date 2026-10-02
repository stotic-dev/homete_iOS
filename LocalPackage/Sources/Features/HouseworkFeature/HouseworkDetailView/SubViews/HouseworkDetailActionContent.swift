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
    @State var isPresentedAddHelperSheet = false

    @Binding var isLoading: Bool
    @Binding var commonErrorContent: DomainErrorAlertContent

    let account: Account
    let item: HouseworkBoardItem
    /// 手伝った人を足せるかどうか（足せる相手がいないときは導線を出さない）
    let canAddHelper: Bool

    var body: some View {
        VStack(spacing: .space16) {
            switch item.state {
            case .incomplete:
                completeButton()
            case .completed:
                if item.canSendThanks(ownUserId: account.id) {
                    sendThanksButton()
                } else if item.canEditThanks(ownUserId: account.id) {
                    editThanksButton()
                }
                if canAddHelper {
                    addHelperButton()
                }
                redoButton()
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
            HouseworkThanksView(item: item, sentThanks: item.sentThanks(ownUserId: account.id))
        }
        .sheet(isPresented: $isPresentedAddHelperSheet) {
            HouseworkAddHelperSheet(item: item, step: .detail)
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

    func addHelperButton() -> some View {
        Button {
            isPresentedAddHelperSheet = true
        } label: {
            Label("手伝った人を追加", systemImage: "person.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
    }

    func redoButton() -> some View {
        Button {
            isLoading = true
            Task {
                await tappedRedoButton()
                isLoading = false
            }
        } label: {
            Label("もう一度やった", systemImage: "arrow.clockwise")
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

    func editThanksButton() -> some View {
        Button {
            isPresentedThanksView = true
        } label: {
            // コメントなしで送った場合は、まだメッセージを送っていないので「添える」にする
            if item.sentThanks(ownUserId: account.id)?.comment == nil {
                Label("メッセージを添える", systemImage: "text.bubble")
                    .frame(maxWidth: .infinity)
            } else {
                Label("送ったメッセージを編集", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity)
            }
        }
        .subPrimaryButtonStyle()
    }

}

// プレゼンテーションロジック

private extension HouseworkDetailActionContent {

    func tappedRedoButton() async {
        guard let cohabitantId else { return }

        do {
            try await houseworkListStore.redo(
                target: item.originalItem,
                now: .now,
                executor: account,
                cohabitantId: cohabitantId,
                step: .detail
            )
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

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
        ),
        canAddHelper: false
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
        ),
        canAddHelper: true
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
        ),
        canAddHelper: true
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_完了_手伝った人を追加できない", traits: .sizeThatFitsLayout) {
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
        ),
        canAddHelper: false
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_完了_コメントなしで送信済み", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "ownAccount", userName: "", fcmToken: nil, cohabitantId: nil),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "executorAccount",
            thanks: ["ownAccount": .init(comment: nil, sentAt: .previewDate(year: 2026, month: 1, day: 1))]
        ),
        canAddHelper: true
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_完了_メッセージ送信済み", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "ownAccount", userName: "", fcmToken: nil, cohabitantId: nil),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "executorAccount",
            thanks: ["ownAccount": .init(comment: "ありがとう", sentAt: .previewDate(year: 2026, month: 1, day: 1))]
        ),
        canAddHelper: true
    )
    .environment(HouseworkListStore())
}
#endif
