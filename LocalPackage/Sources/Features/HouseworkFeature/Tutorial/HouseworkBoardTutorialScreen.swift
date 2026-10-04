//
//  HouseworkBoardTutorialScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// チュートリアルで表示する家事ボード
///
/// 本番と同じ`HouseworkBoardView`にサンプルの家事を渡して表示する。
/// 家事ボードの見た目を変えると、チュートリアルにもそのまま反映される。
/// 操作はスポットライト側で受け止めるため、タップには何も割り当てない。
public struct HouseworkBoardTutorialScreen: View {

    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkStoragePolicy) var storagePolicy

    let page: HouseworkState
    let members: CohabitantMemberList

    /// - Parameters:
    ///   - page: 表示する一覧（未完了・完了）
    ///   - members: サンプルの家事の担当者として出すメンバー
    public init(page: HouseworkState, members: CohabitantMemberList) {
        self.page = page
        self.members = members
    }

    public var body: some View {
        NavigationStack {
            HouseworkBoardView(
                dateList: .constant(.init(
                    anchorDate: now,
                    selectedDate: now,
                    calendar: calendar,
                    storagePolicy: storagePolicy
                )),
                selectedHouseworkState: .constant(page),
                isSelecting: .constant(false),
                selectedHouseworkIDs: .constant([]),
                houseworkBoardList: houseworkBoardList,
                members: members,
                ownUserId: members.ownId,
                loadFailure: nil,
                onTapRetry: {},
                onTapAdd: {},
                onTapItem: { _ in },
                onTapThanks: { _ in },
                onTapStorageLimit: {},
                onTapHouseworkTemplate: {},
                onTapBulkAction: { _ in },
                rowMenu: { _ in EmptyView() }
            )
        }
    }

}

private extension HouseworkBoardTutorialScreen {

    var houseworkBoardList: HouseworkBoardList {
        let items = HouseworkTutorialSample.items(today: calendar.startOfDay(for: now), members: members)
        return .init(items: items.map { .init(originalItem: $0, isRegistered: true) })
    }

}

#if DEBUG
#Preview("HouseworkBoardTutorialScreen_未完了") {
    HouseworkBoardTutorialScreen(
        page: .incomplete,
        members: HouseworkTutorialSample.members(ownId: "ownUserId", ownUserName: "たろう", others: [
            .init(id: "otherUserId", userName: "はなこ"),
        ])
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview(now: .previewDate(year: 2026, month: 5, day: 18))
}

#Preview("HouseworkBoardTutorialScreen_完了") {
    HouseworkBoardTutorialScreen(
        page: .completed,
        members: HouseworkTutorialSample.members(ownId: "ownUserId", ownUserName: "たろう", others: [
            .init(id: "otherUserId", userName: "はなこ"),
        ])
    )
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview(now: .previewDate(year: 2026, month: 5, day: 18))
}
#endif
