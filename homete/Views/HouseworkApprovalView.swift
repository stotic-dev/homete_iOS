//
//  HouseworkApprovalView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import SwiftUI

struct HouseworkApprovalView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var inputMessage = ""
    
    let item: HouseworkItem
    
    var body: some View {
        AppNavigationStackView { _ in
            ScrollView {
                VStack(spacing: DesignSystem.Space.space24) {
                    notificationSection()
                    houseworkPropertySection()
                    inputMessageSection()
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Space.space16)
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
    
    func notificationSection() -> some View {
        section {
            VStack(spacing: DesignSystem.Space.space8) {
                Text("完了報告")
                    .font(with: .headLineM)
                Text("〇〇さんから\n「\(item.title)」の\n完了報告が届きました！")
                    .multilineTextAlignment(.center)
                    .font(with: .body)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Space.space16)
        }
    }
    
    func houseworkPropertySection() -> some View {
        section {
            VStack(spacing: .zero) {
                houseworkPropertyRow("日付") {
                    Text(item.indexedDate, style: .date)
                        .font(with: .headLineS)
                }
                Divider()
                houseworkPropertyRow("ポイント") {
                    Text("\(item.point)pt")
                        .font(with: .headLineS)
                }
                Divider()
                houseworkPropertyRow("完了時間") {
                    Text(item.executedAt ?? .now, style: .time)
                        .font(with: .headLineS)
                }
            }
            .padding(.vertical, DesignSystem.Space.space8)
        }
    }
    
    func houseworkPropertyRow(_ title: String, detailContent: () -> some View) -> some View {
        HStack(spacing: .zero) {
            Text(title)
                .font(with: .body)
                .foregroundStyle(.primary2)
            Spacer()
            detailContent()
        }
        .padding(DesignSystem.Space.space24)
    }
    
    func inputMessageSection() -> some View {
        VStack(spacing: DesignSystem.Space.space16) {
            Text("メッセージ（任意）")
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
            section {
                TextField("感謝を伝えましょう！", text: $inputMessage, axis: .vertical)
                    .font(with: .body)
                    .padding(DesignSystem.Space.space16)
                    .frame(minHeight: 150, alignment: .topLeading)
            }
        }
    }
    
    func section(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(.secondaryBg)
            }
    }
}

#Preview {
    HouseworkApprovalView(item: .init(
        id: "",
        title: "洗濯",
        point: 10,
        metaData: .init(
            indexedDate: .init(timeIntervalSince1970: 0),
            expiredAt: .init(timeIntervalSince1970: 0)
        )
    ))
    .environment(\.locale, .init(identifier: "ja_JP"))
}
