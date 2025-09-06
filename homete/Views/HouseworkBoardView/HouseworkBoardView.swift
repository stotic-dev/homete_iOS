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
    @State var selectedDate = Date.now
    @State var isPresentingAddHouseworkView = false
    
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Space.space16) {
                HouseworkDateHeaderContent(selectedDate: $selectedDate)
                HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                HouseworkBoardListContent(
                    selectedHouseworkState: selectedHouseworkState,
                    houseworkBoardList: $houseworkBoardList
                )
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Space.space16)
            addHouseworkButton {
                isPresentingAddHouseworkView = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, DesignSystem.Space.space24)
            .padding(.bottom, DesignSystem.Space.space24)
        }
        .sheet(isPresented: $isPresentingAddHouseworkView) {
            RegisterHouseworkView()
        }
    }
}

private extension HouseworkBoardView {
    
    @ViewBuilder
    func addHouseworkButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
        }
        .floatingButtonStyle()
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
