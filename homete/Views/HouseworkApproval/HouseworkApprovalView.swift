//
//  HouseworkApprovalView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

struct HouseworkApprovalView: View {
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @CommonError var commonError
    
    @State var inputMessage = ""
    
    let item: HouseworkItem
    
    var body: some View {
        AppNavigationStackView { _ in
            ScrollView {
                VStack(spacing: .space40) {
                    VStack(spacing: .space24) {
                        if let executorId = item.executorId,
                           let executorUserName = cohabitantStore.members.userName(executorId) {
                            notificationSection(executorUserName)
                        }
                        houseworkPropertySection()
                        inputMessageSection()
                    }
                    actionButtonContent()
                }
                .padding(.horizontal, .space16)
                .padding(.bottom, .space24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("家事の確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                navigationLeadingItem()
            }
        }
    }
}

private extension HouseworkApprovalView {
    
    func navigationLeadingItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationBarButton(label: .close) {
                dismiss()
            }
        }
    }
    
    func notificationSection(_ executorName: String) -> some View {
        section {
            VStack(spacing: .zero) {
                Text("\(executorName)さんから")
                Text("「\(item.title)」の")
                Text("完了報告が届きました")
            }
            .font(with: .body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .space16)
        }
    }
    
    func houseworkPropertySection() -> some View {
        section {
            HouseworkItemPropertyListContent(item: item)
                .padding(.vertical, .space8)
        }
    }
    
    func inputMessageSection() -> some View {
        VStack(spacing: .space16) {
            Text("メッセージ")
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
            section {
                TextField("感謝を伝えましょう！", text: $inputMessage, axis: .vertical)
                    .font(with: .body)
                    .padding(.space16)
                    .frame(minHeight: 150, alignment: .topLeading)
            }
        }
    }
    
    func section(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(.subSurface)
            }
    }
    
    func actionButtonContent() -> some View {
        VStack(spacing: .space16) {
            Button {
                Task {
                    await tappedApproveButton()
                }
            } label: {
                Text("完了にする")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
            Button {
                // TODO: 家事を未完了に戻す
            } label: {
                Text("未完了に戻す")
                    .frame(maxWidth: .infinity)
            }
            .destructiveButtonStyle()
        }
        .disabled(inputMessage.isEmpty)
    }
}

// MARK: プレゼンテーションロジック

private extension HouseworkApprovalView {
    
    func tappedApproveButton() async {
        
        do {
            
            try await houseworkListStore.approved(
                target: item,
                now: .now,
                reviwer: account,
                comment: inputMessage
            )
            dismiss()
        } catch {
            
            commonError = .init(error: error)
        }
    }
}

#Preview {
    HouseworkApprovalView(item: .init(
        id: "",
        title: "洗濯",
        point: 10,
        metaData: .init(
            indexedDate: .init(.init(timeIntervalSince1970: 0)),
            expiredAt: .init(timeIntervalSince1970: 0)
        ),
        executorId: "test",
        executedAt: .distantFuture,
    ))
    .setupEnvironmentForPreview()
    .environment(CohabitantStore(members: .init(value: [.init(id: "test", userName: "hogehoge")])))
    .environment(HouseworkListStore())
}
