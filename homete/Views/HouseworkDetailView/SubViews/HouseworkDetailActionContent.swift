//
//  HouseworkDetailActionContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import SwiftUI

struct HouseworkDetailActionContent: View {
    
    @Binding var isLoading: Bool
    @Binding var commonErrorContent: DomainErrorAlertContent
    
    var houseworkListStore: HouseworkListStore
    let account: Account
    let item: HouseworkItem
    
    var body: some View {
        VStack(spacing: DesignSystem.Space.space16) {
            switch item.state {
            case .incomplete:
                requestReviewButton()
            case .pendingApproval:
                if item.isApprovable(account.id) {
                    approvalButton()
                    rejectButton()
                }
                else {
                    undoChangeStateButton()
                }
            case .completed:
                undoChangeStateButton()
            }
        }
    }
}

private extension HouseworkDetailActionContent {
    
    func requestReviewButton() -> some View {
        Button {
            Task {
                await tappedRequestConfirmButton()
            }
        } label: {
            Label("確認してもらう", systemImage: "paperplane.fill")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
    }
    
    func undoChangeStateButton() -> some View {
        Button {
            // TODO: 未完了に戻す
        } label: {
            Label("未完了に戻す", systemImage: "arrow.uturn.backward")
                .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
    }
    
    func approvalButton() -> some View {
        Button {
            Task {
                // TODO: 承認する
            }
        } label: {
            Label("「ありがとう」を伝える", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
    }
    
    func rejectButton() -> some View {
        Button {
            Task {
                // TODO: 拒否する
            }
        } label: {
            Text("やり直してもらう")
                .frame(maxWidth: .infinity)
        }
        .primaryButtonStyle()
    }
}

// プレゼンテーションロジック

private extension HouseworkDetailActionContent {
    
    func tappedRequestConfirmButton() async {
        
        isLoading = true
        
        do {
            try await houseworkListStore.requestReview(
                target: item,
                now: .now,
                executor: account.id
            )
        }
        catch {
            commonErrorContent = .init(error: error)
        }
        
        isLoading = false
    }
}

#Preview("HouseworkDetailActionContent_未完了", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        houseworkListStore: .init(houseworkClient: .previewValue, cohabitantPushNotificationClient: .previewValue),
        account: .init(id: "", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            title: "洗濯",
            point: 10,
            metaData: .init(indexedDate: .distantPast, expiredAt: .distantFuture)
        )
    )
}

#Preview("HouseworkDetailActionContent_承認待ち_実施者アカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        houseworkListStore: .init(houseworkClient: .previewValue, cohabitantPushNotificationClient: .previewValue),
        account: .init(id: "dummy", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            indexedDate: .distantPast,
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "dummy",
            executedAt: nil,
            expiredAt: .distantPast
        )
    )
}

#Preview("HouseworkDetailActionContent_承認待ち_確認者アカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        houseworkListStore: .init(houseworkClient: .previewValue, cohabitantPushNotificationClient: .previewValue),
        account: .init(id: "dummy", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            indexedDate: .distantPast,
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "",
            executedAt: nil,
            expiredAt: .distantPast
        )
    )
}
