//
//  DashboardTutorialView.swift
//  LocalPackage
//

import ContributionFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// チュートリアルで表示するダッシュボード
///
/// 本番と同じ`DashboardContent`と各セクションのUIにサンプルの家事を渡して表示する。
/// ダッシュボードの見た目を変えると、チュートリアルにもそのまま反映される。
/// 操作はスポットライト側で受け止めるため、タップには何も割り当てない。
public struct DashboardTutorialView: View {

    @Environment(\.calendar) var calendar

    let now: Date

    /// - Parameter now: 現在日時。この日の家事としてサンプルを並べる
    public init(now: Date) {
        self.now = now
    }

    public var body: some View {
        NavigationStack {
            DashboardContent(
                loadFailure: nil,
                // 広告は説明の対象ではないため出さない
                showsAdvertisement: false,
                isLoading: false,
                showsTemplateBanner: false,
                onTapRetry: {},
                onTapRemoveAdsPromotion: {},
                onTapTemplateBanner: {},
                todaySummary: {
                    TodayHouseworkSummaryContent(
                        summary: todaySummary,
                        members: HouseworkTutorialSample.members,
                        onTapRegister: {},
                        onTapItem: { _ in },
                        onTapComplete: { _ in },
                        onTapShowMore: {},
                        rowMenu: { _ in EmptyView() }
                    )
                },
                advertisement: {
                    EmptyView()
                },
                contributionSummary: {
                    ContributionSummaryTutorialContent(members: HouseworkTutorialSample.members)
                }
            )
            .homeNavigationBar(onTapSetting: {})
        }
    }

}

private extension DashboardTutorialView {

    var todaySummary: TodayHouseworkSummary {
        let today = calendar.startOfDay(for: now)
        return .make(
            storedAllItems: .init(value: [HouseworkTutorialSample.dailyList(today: today)]),
            template: nil,
            now: now,
            calendar: calendar,
            // サンプルは今日の家事だけなので、保存期間の制限に関わらない
            storagePolicy: .premium
        )
    }

}

#if DEBUG
#Preview("DashboardTutorialView") {
    DashboardTutorialView(now: .previewDate(year: 2026, month: 5, day: 18))
        .apply(theme: .init())
        .setupEnvironmentForPreview()
        .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
}
#endif
