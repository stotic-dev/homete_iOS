//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkBoardView: View {
    @Environment(\.calendar) var calendar
    @Environment(\.now) var anchorDate
    @Environment(HouseworkListStore.self) var houseworkListStore

    @State var navigationPath = AppNavigationPath<HouseworkBoardRoute>()
    @State var dateList = HouseworkDateList()
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var houseworkBoardList = HouseworkBoardList(items: [])
    @State var isPresentingAddHouseworkView = false
    
    public static func instantiate() -> Self {
        HouseworkBoardView()
    }

    public var body: some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    HouseworkDateHeaderContent(dateList: $dateList)
                    VStack(spacing: .space16) {
                        HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                        TabView(selection: $selectedHouseworkState) {
                            ForEach(HouseworkState.allCases) { state in
                                HouseworkBoardListContent(
                                    houseworkListStore: houseworkListStore,
                                    state: state,
                                    list: houseworkBoardList,
                                    selectedHouseworkState: $selectedHouseworkState,
                                    onCreateTapped: { isPresentingAddHouseworkView = true }
                                )
                                .tag(state)
                            }
                        }
                        #if os(iOS)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        #endif
                        Spacer()
                    }
                    .padding(.horizontal, .space16)
                }
                addHouseworkButton {
                    isPresentingAddHouseworkView = true
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, .space24)
                .padding(.bottom, .space24)
            }
            .navigationDestination(for: HouseworkBoardRoute.self) { route in
                navigationHandler(route)
            }
            .environment(\.houseworkBoardNavigationPath, navigationPath)
        }
        .sheet(isPresented: $isPresentingAddHouseworkView) {
            RegisterHouseworkView(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: dateList.selectedDate,
                    items: [],
                    calendar: calendar
                )
            )
        }
        .onChange(of: houseworkListStore.items) {
            withAnimation {
                updateHouseworkBoardList()
            }
        }
        .onChange(of: dateList.selectedDate) {
            withAnimation {
                updateHouseworkBoardList()
            }
        }
        .onAppear {
            withAnimation {
                updateHouseworkBoardList()
            }
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
    
    @ViewBuilder
    func navigationHandler(_ route: HouseworkBoardRoute) -> some View {
        switch route {
        case .houseworkDetail(let item):
            HouseworkDetailView(item: item)
        }
    }
}

private extension HouseworkBoardView {
    
    func updateHouseworkBoardList() {
        
        houseworkBoardList = .init(
            dailyList: houseworkListStore.items.value,
            selectedDate: dateList.selectedDate,
            calendar: calendar
        )
    }
}

#Preview {
    let list = HouseworkBoardList(items: [
        .init(
            id: "1",
            title: "洗濯",
            point: 20,
            metaData: .init(
                indexedDate: .init(value: "0001/01/01"),
                expiredAt: .distantPast
            )
        )
    ])
    HouseworkBoardView(
        dateList: .init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        ),
        houseworkBoardList: list
    )
    .apply(theme: .init())
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue,
        houseworkManager: .init(
            houseworkClient: .previewValue,
            allItems: list.items
        )
    ))
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .snapshotForPreview(delay: 2)
}
