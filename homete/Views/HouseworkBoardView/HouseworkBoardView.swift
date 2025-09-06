//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardView: View {
    
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var houseworkBoardList = HouseworkBoardList(items: [])
    
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Space.space16) {
                HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                HouseworkBoardListContent(selectedHouseworkState: selectedHouseworkState, houseworkBoardList: $houseworkBoardList)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Space.space16)
            addHouseworkButton {
                // TODO: 家事追加画面へ遷移
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, DesignSystem.Space.space24)
            .padding(.bottom, DesignSystem.Space.space24)
        }
    }
}

private extension HouseworkBoardView {
    
    @ViewBuilder
    func addHouseworkButton(action: @escaping () -> Void) -> some View {
        if #available(iOS 26.0, *) {
            Button {
                action()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .padding(DesignSystem.Space.space16)
                    .foregroundStyle(.commonBlack)
            }
            .glassEffect(.regular.tint(.primary1))
        } else {
            Button {
                action()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .padding(DesignSystem.Space.space16)
                    .foregroundStyle(.commonBlack)
                    .clipShape(Circle())
                    .background {
                        Circle()
                            .foregroundStyle(.primary1)
                    }
            }
        }
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
