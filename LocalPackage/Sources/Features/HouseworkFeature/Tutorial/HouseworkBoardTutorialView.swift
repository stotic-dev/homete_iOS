//
//  HouseworkBoardTutorialView.swift
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
public struct HouseworkBoardTutorialView: View {

    @Environment(\.calendar) var calendar

    let page: HouseworkState
    let now: Date

    /// - Parameters:
    ///   - page: 表示する一覧（未完了・完了）
    ///   - now: 現在日時。この日の家事としてサンプルを並べる
    public init(page: HouseworkState, now: Date) {
        self.page = page
        self.now = now
    }

    public var body: some View {
        NavigationStack {
            HouseworkBoardView(
                dateList: .constant(.init(
                    anchorDate: now,
                    selectedDate: now,
                    calendar: calendar,
                    // 保存期間の案内は説明の対象ではないため出さない
                    storagePolicy: .premium
                )),
                selectedHouseworkState: .constant(page),
                isSelecting: .constant(false),
                selectedHouseworkIDs: .constant([]),
                houseworkBoardList: houseworkBoardList,
                members: HouseworkTutorialSample.members,
                ownUserId: HouseworkTutorialSample.members.ownId,
                loadFailure: nil,
                onTapRetry: {},
                onTapAdd: {},
                onTapItem: { _ in },
                onTapComplete: { _ in },
                onTapThanks: { _ in },
                onTapStorageLimit: {},
                onTapHouseworkTemplate: {},
                onTapBulkAction: { _ in },
                rowMenu: { _ in EmptyView() }
            )
        }
    }

}

private extension HouseworkBoardTutorialView {

    var houseworkBoardList: HouseworkBoardList {
        let items = HouseworkTutorialSample.items(today: calendar.startOfDay(for: now))
        return .init(items: items.map { .init(originalItem: $0, isRegistered: true) })
    }

}

#if DEBUG
#Preview("HouseworkBoardTutorialView_未完了") {
    HouseworkBoardTutorialView(page: .incomplete, now: .previewDate(year: 2026, month: 5, day: 18))
        .apply(theme: .init())
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
}

#Preview("HouseworkBoardTutorialView_完了") {
    HouseworkBoardTutorialView(page: .completed, now: .previewDate(year: 2026, month: 5, day: 18))
        .apply(theme: .init())
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
}
#endif
