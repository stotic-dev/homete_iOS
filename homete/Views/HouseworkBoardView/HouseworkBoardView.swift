//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardView: View {
    
    @Environment(\.calendar) var calendar
    @Environment(HouseworkListStore.self) var houseworkListStore
    
    @State var navigationPath = CustomNavigationPath<HouseworkBoardNavigationPathElement>(path: [])
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var houseworkBoardList = HouseworkBoardList(items: [])
    @State var selectedDate = Date.now
    @State var isPresentingAddHouseworkView = false
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
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
            .navigationDestination(for: HouseworkBoardNavigationPathElement.self) { element in
                element.destination()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings) {
                        navigationPath.push(.settings)
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingAddHouseworkView) {
            RegisterHouseworkView(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: selectedDate,
                    items: [],
                    calendar: calendar
                )
            )
        }
        .onChange(of: houseworkListStore.items) {
            updateHouseworkBoardList()
        }
        .onChange(of: selectedDate) {
            updateHouseworkBoardList()
        }
        .onAppear {
            updateHouseworkBoardList()
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

private extension HouseworkBoardView {
    
    func updateHouseworkBoardList() {
        houseworkBoardList = .init(
            dailyList: houseworkListStore.items,
            selectedDate: selectedDate,
            calendar: calendar
        )
    }
}

#Preview {
    HouseworkBoardView(
        houseworkBoardList: .init(
            items: [
                .init(id: "1", indexedDate: .now, title: "洗濯", point: 20, state: .incomplete, expiredAt: .now),
                .init(id: "2", indexedDate: .now, title: "ゴミ捨て", point: 100, state: .pendingApproval, expiredAt: .now),
                .init(id: "3", indexedDate: .now, title: "風呂掃除", point: 10, state: .completed, expiredAt: .now)
            ]
        ),
        selectedDate: .distantPast
    )
    .apply(theme: .init())
    .environment(HouseworkListStore(houseworkClient: .previewValue))
    .environment(\.locale, .init(identifier: "ja_JP"))
}
