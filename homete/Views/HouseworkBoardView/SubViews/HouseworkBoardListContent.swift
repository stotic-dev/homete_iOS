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
                    HStack(spacing: DesignSystem.Space.space16) {
                        pointLabel(item.point)
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

private extension HouseworkBoardListContent {
    
    func pointLabel(_ point: Int) -> some View {
        Text(point.formatted())
            .font(with: .headLineM)
            .foregroundStyle(.commonWhite)
            .padding(DesignSystem.Space.space8)
            .frame(minWidth: 45)
            .background {
                GeometryReader {
                    RoundedRectangle(cornerRadius: $0.size.height / 2)
                        .fill(.primary2)
                }
            }
    }
}

#Preview {
    @Previewable @State var list = HouseworkBoardList(items: [
        .init(id: "1", indexedDate: .now, title: "洗濯", point: 20, state: .incomplete, expiredAt: .now),
        .init(id: "2", indexedDate: .now, title: "掃除", point: 100, state: .incomplete, expiredAt: .now),
        .init(id: "3", indexedDate: .now, title: "料理", point: 1, state: .incomplete, expiredAt: .now)
    ])
    HouseworkBoardListContent(
        selectedHouseworkState: .incomplete,
        houseworkBoardList: $list
    )
}
