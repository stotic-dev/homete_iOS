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
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    
    @State var summary: [PointSummary] = []
    
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
        ContributionSummaryContent(
            summary: summary,
            members: cohabitantStore.members
        )
        .task(id: contributionStore.contiribution) {
            await onChangeContribution()
        }
    }
}

private extension ContributionSummaryComponent {
    
    func onChangeContribution() async {
        
        let contribution = contributionStore.contiribution
        let allUserIds = cohabitantStore.members.value.map(\.id)
        
        summary = await Task.detached {
            
            await contribution.calculatePointSummaries(
                allUserIds: allUserIds,
                month: now,
                calendar: calendar
            )
        }.value
    }
}

struct ContributionSummaryContent: View {

    @Environment(\.loginContext.account.id) var userId
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now

    let summary: [PointSummary]
    let members: CohabitantMemberList
    @State var isShowingLegend = false

    var body: some View {
        VStack(spacing: .zero) {
            HStack {
                Text(monthTitle)
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
            .padding(.vertical, .space16)
            Divider()
            ContributionBarChart(
                summaries: sortedSummary,
                userNames: Dictionary(
                    uniqueKeysWithValues: members.value.map { ($0.id, $0.userName) }
                ),
                myUserId: userId
            )
            Divider()
            ForEach(sortedSummary) { item in
                SummaryRow(
                    userName: members.userName(item.userId) ?? item.userId,
                    isMe: item.userId == userId,
                    monthlyPoint: item.monthlyPoint,
                    achievedCount: item.achievedCount
                )
                Divider()
                    .padding(.leading, .space16)
            }
        }
    }

    private var sortedSummary: [PointSummary] {
        summary.sorted { $0.monthlyPoint > $1.monthlyPoint }
    }

    private var monthTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月の家事貢献度サマリー"
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        summary: [
            PointSummary(userId: "user1", monthlyPoint: 120, achievedCount: 5),
            PointSummary(userId: "user2", monthlyPoint: 40, achievedCount: 2)
        ],
        members: .init(value: [
            .init(id: "user1", userName: "田中"),
            .init(id: "user2", userName: "佐藤")
        ])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}
