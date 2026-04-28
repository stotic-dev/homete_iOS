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
        
        let summary = await Task.detached {
            await contribution.calculatePointSummaries(
                allUserIds: allUserIds,
                month: now,
                calendar: calendar
            )
        }.value
        
        withAnimation {
            self.summary = summary
        }
    }
}

struct ContributionSummaryContent: View {

    @Environment(\.loginContext.account.id) var userId
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now

    let summary: AllUserPointSummary
    let members: CohabitantMemberList
    @State var isShowingLegend = false

    var body: some View {
        VStack(spacing: .zero) {
            Text(monthTitle)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space16)
            Divider()
            ContributionGraphSection(
                summaries: summary.items,
                userNames: Dictionary(
                    uniqueKeysWithValues: members.value.map { ($0.id, $0.userName) }
                ),
                myUserId: userId
            )
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
            ForEach(summary.makeRanking(members: members, myUserId: userId)) { item in
                SummaryRow(item: item)
                Divider()
                    .padding(.leading, .space16)
            }
        }
    }

    private var monthTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月の家事貢献度サマリー"
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContributionSummaryContent(
        summary: AllUserPointSummary(items: [
            PointSummary(userId: "user1", monthlyPoint: 120, achievedCount: 5),
            PointSummary(userId: "user2", monthlyPoint: 40, achievedCount: 2)
        ]),
        members: .init(value: [
            .init(id: "user1", userName: "田中"),
            .init(id: "user2", userName: "佐藤")
        ])
    )
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 1))
    .setupEnvironmentForPreview()
}
