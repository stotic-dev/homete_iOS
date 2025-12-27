//
//  HouseworkDetailActionContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import SwiftUI

struct HouseworkDetailActionContent: View {
    @Environment(HouseworkListStore.self) var houseworkListStore
    @State var isPresentedApprovalView = false
    
    @Binding var isLoading: Bool
    @Binding var commonErrorContent: DomainErrorAlertContent
    
    let account: Account
    let item: HouseworkItem
    
    var body: some View {
        VStack(spacing: .space16) {
            switch item.state {
            case .incomplete:
                requestReviewButton()
            case .pendingApproval:
                if item.isApprovable(account.id) {
                    approvalButton()
                }
                else {
                    undoChangeStateButton()
                }
            case .completed:
                undoChangeStateButton()
            }
        }
        .fullScreenCover(isPresented: $isPresentedApprovalView) {
            HouseworkApprovalView(item: item)
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
            isPresentedApprovalView = true
        } label: {
            Label("確認する", systemImage: "checkmark.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .subPrimaryButtonStyle()
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
        account: .init(id: "", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            title: "洗濯",
            point: 10,
            metaData: .init(indexedDate: .init(.distantPast), expiredAt: .distantFuture)
        )
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_承認待ち_実施者アカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "dummy", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            indexedDate: .init(.distantPast),
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "dummy",
            executedAt: nil,
            expiredAt: .distantPast
        )
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkDetailActionContent_承認待ち_確認者アカウント", traits: .sizeThatFitsLayout) {
    HouseworkDetailActionContent(
        isLoading: .constant(false),
        commonErrorContent: .constant(.initial),
        account: .init(id: "dummy", displayName: "", fcmToken: nil),
        item: .init(
            id: "",
            indexedDate: .init(.distantPast),
            title: "洗濯",
            point: 10,
            state: .pendingApproval,
            executorId: "",
            executedAt: nil,
            expiredAt: .distantPast
        )
    )
    .environment(HouseworkListStore())
}
