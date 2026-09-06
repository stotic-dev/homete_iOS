//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkBoardView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var anchorDate
    @Environment(\.routeResolver) var router
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(SubscriptionStore.self) var subscriptionStore

    @Binding var houseworkBoardList: HouseworkBoardList
    @Binding var dateList: HouseworkDateList

    @State var navigationPath = AppNavigationPath<HouseworkBoardRoute>()
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var isPresentingAddHouseworkView = false
    @State var isShowHouseworkTemplate = false
    @State var isShowPaywall = false
    @State var isSelecting = false

    let onUpdateHouseboardList: () -> Void

    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    HouseworkDateHeaderContent(dateList: $dateList) {
                        tappedStorageLimitCell()
                    }
                    VStack(spacing: .space16) {
                        HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                        TabView(selection: $selectedHouseworkState) {
                            ForEach(HouseworkState.pageableCases) { state in
                                HouseworkBoardListContent(
                                    houseworkListStore: houseworkListStore,
                                    state: state,
                                    list: houseworkBoardList,
                                    selectedHouseworkState: $selectedHouseworkState,
                                    isSelecting: $isSelecting,
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
            .softTopScrollEdgeEffect()
            .trailingToolbarItem {
                HStack(spacing: .space16) {
                    Button(isSelecting ? "完了" : "選択") {
                        withAnimation {
                            isSelecting.toggle()
                        }
                    }
                    NavigationBarButton(label: .houseworkTemplate) {
                        isShowHouseworkTemplate = true
                    }
                }
            }
            .environment(\.houseworkBoardNavigationPath, navigationPath)
        }
        .sheet(isPresented: $isPresentingAddHouseworkView) {
            RegisterHouseworkView(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: dateList.selectedDate,
                    items: [],
                    calendar: calendar,
                    storagePolicy: storagePolicy
                ),
                step: .board
            )
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .fullScreenCoverOnIOS(
            isPresented: $isShowPaywall,
            onDismiss: { dismissedPaywall() },
            content: { router.resolve(.paywall) }
        )
        .onChange(of: houseworkListStore.items) {
            withAnimation {
                onUpdateHouseboardList()
            }
        }
        .onChange(of: dateList.selectedDate) {
            withAnimation {
                onUpdateHouseboardList()
            }
        }
        .onChange(of: selectedHouseworkState) {
            withAnimation {
                isSelecting = false
            }
        }
        .trackScreenView(.houseworkBoard)
    }

}

private extension HouseworkBoardView {

    func tappedStorageLimitCell() {
        analyticsClient.log(.paywall(.shown(step: .boardStorageLimit)))
        isShowPaywall = true
    }

    func dismissedPaywall() {
        analyticsClient.log(.paywall(.closed(step: .boardStorageLimit, isPremium: subscriptionStore.isPremium)))
    }

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
        case let .houseworkDetail(item):
            HouseworkDetailView(item: item)
        }
    }

}

#if DEBUG
#Preview {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            title: "洗濯",
            point: 20
        ),
    ])
    HouseworkBoardView(
        houseworkBoardList: .constant(list),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        onUpdateHouseboardList: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
    .environment(SubscriptionStore())
}
#endif
