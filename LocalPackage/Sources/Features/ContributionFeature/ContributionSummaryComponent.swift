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
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(\.loginContext.account.id) var userId
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar

    @State var summary: AllUserPointSummary = .init()

    public static func make() -> some View {
        DependenciesInjectLayer {
            ContributionSummaryComponent()
                .environment(ContributionStore(
                    houseworkManager: $0.houseworkManager,
                    calendar: Calendar.autoupdatingCurrent
                ))
        }
    }

    public var body: some View {
        ContributionSummaryContent(summaries: summary)
            .task(id: contributionStore.contiribution) {
                await onChangeContribution()
            }
    }
}

private extension ContributionSummaryComponent {

    func onChangeContribution() async {

        let contribution = contributionStore.contiribution
        let members = cohabitantStore.members
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

    let summaries: AllUserPointSummary
    @State var isShowingLegend = false

    var body: some View {
        VStack(spacing: .zero) {
            Text(monthTitle)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space16)
            if summaries.hasData {
                Divider()
                ContributionGraphSection(summaries: summaries)
                Divider()
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
                .padding(.horizontal, .space16)
                .padding(.top, .space16)
                ForEach(summaries.makeRanking()) { item in
                    SummaryRow(item: item)
                    Divider()
                        .padding(.leading, .space16)
                }
            } else {
                // TODO: 今日の家事完了を促すメッセージとアクションの導線を追加する
                ContentUnavailableView("まだ達成された家事がありません", systemImage: "house.circle")
            }
        }
    }

    private var monthTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月の家事貢献度サマリー"
    }
}

#Preview("ContributionSummaryContent_データ有り", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
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
            )
        ])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}

#Preview("ContributionSummaryContent_データ無し", traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        summaries: AllUserPointSummary(items: [])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}
