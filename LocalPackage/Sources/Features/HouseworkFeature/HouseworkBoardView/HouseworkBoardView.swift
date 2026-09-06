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
    @Environment(HouseworkListStore.self) var houseworkListStore

    @Binding var houseworkBoardList: HouseworkBoardList
    @Binding var dateList: HouseworkDateList

    @State var navigationPath = AppNavigationPath<HouseworkBoardRoute>()
    @State var selectedHouseworkState = HouseworkState.incomplete
    @State var isPresentingAddHouseworkView = false
    @State var isShowHouseworkTemplate = false
    @State var isShowPaywall = false
    @State var isSelecting = false

    @LoadingState var loadingState

    /// 家事の購読に失敗している場合のエラー内容
    let loadFailure: DomainError?
    let onUpdateHouseboardList: () -> Void
    let onRetry: () async -> Void

    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                if let loadFailure {
                    LoadErrorView(error: loadFailure) {
                        loadingState.task {
                            await onRetry()
                        }
                    }
                } else {
                    boardContent()
                    addHouseworkButton {
                        isPresentingAddHouseworkView = true
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, .space24)
                    .padding(.bottom, .space24)
                }
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
                )
            )
        }
        .fullScreenCoverOnIOS(isPresented: $isShowHouseworkTemplate) {
            router.resolve(.houseworkTemplate)
        }
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
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
        .fullScreenLoadingIndicator(loadingState)
    }

}

private extension HouseworkBoardView {

    func boardContent() -> some View {
        VStack(spacing: .space16) {
            HouseworkDateHeaderContent(dateList: $dateList) {
                isShowPaywall = true
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
        loadFailure: nil,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
}

#Preview("HouseworkBoardView_読み込みエラー") {
    HouseworkBoardView(
        houseworkBoardList: .constant(.init(items: [])),
        dateList: .constant(.init(
            anchorDate: .distantPast,
            selectedDate: .distantPast,
            calendar: .japanese
        )),
        loadFailure: .noNetwork,
        onUpdateHouseboardList: {},
        onRetry: {}
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
    .environment(HouseworkListStore())
}
#endif
