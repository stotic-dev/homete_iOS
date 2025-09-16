//
//  HouseworkBoardListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardListContent: View {
    
    let selectedHouseworkState: HouseworkState
    @Binding var houseworkBoardList: HouseworkBoardList
    
    var body: some View {
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
    }
}
