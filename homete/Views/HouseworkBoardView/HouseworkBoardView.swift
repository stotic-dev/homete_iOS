//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardView: View {
    
    @State var selectedHouseworkState: HouseworkState = .incomplete
    @State var houseworkBoardList: HouseworkBoardList = .init(items: [])
    
    var body: some View {
        VStack(spacing: DesignSystem.Space.space16) {
            HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
            List {
                ForEach(houseworkBoardList.items(matching: selectedHouseworkState)) { item in
                    Button {
                        // TODO: 承認依頼を行う
                    } label: {
                        HStack {
                            Text(item.title)
                                .font(with: .body)
                            Spacer()
                        }
                        .padding(.vertical, DesignSystem.Space.space8)
                    }
                }
                .listRowSpacing(.zero)
                .listRowSeparator(.hidden)
                // TODO: 左スワイプで家事を削除する
            }
            .listStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

#Preview {
    HouseworkBoardView(
        houseworkBoardList: .init(
            items: [
                .init(id: "1", title: "洗濯", state: .incomplete),
                .init(id: "2", title: "ゴミ捨て", state: .pendingApproval),
                .init(id: "3", title: "風呂掃除", state: .completed)
            ]
        )
    )
    .apply(theme: .init())
}
