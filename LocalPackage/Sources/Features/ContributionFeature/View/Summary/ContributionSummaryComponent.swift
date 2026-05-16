//
//  ContributionSummaryComponent.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct ContributionSummaryComponent: View {

    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account.id) var userId
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar

    @State var summary: AllUserPointSummary = .init()
    @State var isShowAnalytics = false

    public static func make() -> some View {
        ContributionSummaryComponent()
    }

    public var body: some View {
        ContributionSummaryContent(isShowAnalytics: $isShowAnalytics, summaries: summary)
            .onChange(of: members) {
                Task {
                    await onChangeContribution()
                }
            }
            .task(id: contributionStore.contiribution) {
                await onChangeContribution()
            }
            .navigationDestination(isPresented: $isShowAnalytics) {
                ContributionAnalyticsScreen.make()
                    .environment(contributionStore)
            }
    }

}

private extension ContributionSummaryComponent {

    func onChangeContribution() async {
        let contribution = contributionStore.contiribution
        print("did change contribution: \(contribution), members: \(members)")

        let myUserId = userId

        let summary = await Task.detached {
            await contribution.calculatePointSummaries(
                month: now,
                calendar: calendar,
                members: members,
                myUserId: myUserId
            )
        }.value

        withAnimation {
            self.summary = summary
        }
    }

}

struct ContributionSummaryContent: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now

    @Binding var isShowAnalytics: Bool

    let summaries: AllUserPointSummary
    @State var isShowingLegend = false

    var body: some View {
        VStack(spacing: .space8) {
            Text(monthTitle)
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.onSurface)
            Divider()
            if summaries.hasData {
                VStack(spacing: .zero) {
                    graphContent(summaries)
                    Divider()
                        .padding(.vertical, .space24)
                    rankingContent(summaries.makeRanking())
                }
            } else {
                // TODO: 今日の家事完了を促すメッセージとアクションの導線を追加する
                ContentUnavailableView("今月はまだ達成された家事がありません", systemImage: "house.circle")
                    .frame(height: 240)
            }
        }
    }

}

// MARK: - UI定義

private extension ContributionSummaryContent {

    func graphContent(_ summaries: AllUserPointSummary) -> some View {
        VStack(spacing: .space16) {
            ContributionGraphSection(summaries: summaries)
            Button("もっと詳しく見る") {
                isShowAnalytics = true
            }
            .primaryButtonStyle()
        }
    }

    func rankingContent(_ ranking: [ContributionRankItem]) -> some View {
        VStack(spacing: .space8) {
            HStack(spacing: .zero) {
                Text("今月の貢献ランキング")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                Spacer()
                Button {
                    isShowingLegend = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .popover(isPresented: $isShowingLegend) {
                    LegendPopover()
                        .presentationCompactAdaptation(.popover)
                }
            }
            ForEach(ranking) { item in
                SummaryRow(item: item)
                Divider()
                    .padding(.leading, .space16)
            }
        }
    }

    var monthTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月の家事貢献度サマリー"
    }

}

#if DEBUG
#Preview("ContributionSummaryContent_データ有り", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        isShowAnalytics: .constant(false),
        summaries: AllUserPointSummary(items: [
            UserPointSummary(
                userId: "user1",
                userName: "田中",
                isMe: true,
                monthlyPoint: .init(value: 120),
                achievedCount: 5
            ),
            UserPointSummary(
                userId: "user2",
                userName: "佐藤",
                isMe: false,
                monthlyPoint: .init(value: 40),
                achievedCount: 2
            ),
        ])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}

#Preview("ContributionSummaryContent_データ無し", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        isShowAnalytics: .constant(false),
        summaries: AllUserPointSummary(items: [])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}
#endif
