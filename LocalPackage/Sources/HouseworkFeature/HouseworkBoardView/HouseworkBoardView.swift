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
    @Environment(HouseworkListStore.self) var houseworkListStore

    @State var navigationPath = AppNavigationPath<HouseworkBoardRoute>()
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var houseworkBoardList = HouseworkBoardList(items: [])
    @State var selectedDate: Date = .now
    @State var isPresentingAddHouseworkView = false
    
    public static func instantiate() -> Self {
        HouseworkBoardView()
    }

    public var body: some View {
        AppNavigationStackView(path: $navigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    HouseworkDateHeaderContent(selectedDate: $selectedDate)
                    HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                    HouseworkBoardListContent(
                        houseworkListStore: houseworkListStore,
                        state: selectedHouseworkState,
                        list: houseworkBoardList
                    )
                    Spacer()
                }
                .padding(.horizontal, .space16)
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
                    selectedDate: selectedDate,
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
        .onChange(of: selectedDate) {
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
            selectedDate: selectedDate,
            calendar: calendar
        )
    }
}

#Preview {
    HouseworkBoardView(selectedDate: .distantPast)
    .apply(theme: .init())
    .environment(HouseworkListStore(
        houseworkClient: .previewValue,
        cohabitantPushNotificationClient: .previewValue,
        items: [
            .init(
                items: [
                    .init(
                        id: "1",
                        title: "洗濯",
                        point: 20,
                        metaData: .init(
                            indexedDate: .init(value: "0001/01/01"),
                            expiredAt: .distantPast
                        )
                    )
                ],
                metaData: .init(
                    indexedDate: .init(value: "0001/01/01"),
                    expiredAt: .now
                )
            )
        ]
    ))
    .setupEnvironmentForPreview()
}
