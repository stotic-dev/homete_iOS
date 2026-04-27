//
//  ConributionSummaryView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct ContributionSummaryComponent: View {
    @Environment(\.calendar) var calendar
    
    public static func make() -> some View {
        ContributionSummaryComponent()
    }
    
    public var body: some View {
        DependenciesInjectLayer {
            ContributionSummaryContent()
                .environment(ContributionStore(
                    houseworkManager: $0.houseworkManager,
                    calendar: calendar
                ))
        }
    }
}

struct ContributionSummaryContent: View {
    
    @Environment(ContributionStore.self) var contributionStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(\.loginContext.account.id) var userId
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    
    @State var summary: [PointSummary] = []
    
    var body: some View {
        VStack(spacing: .zero) {
            
        }
        .task(id: contributionStore.contiribution) {
            await onChangeContribution()
        }
    }
}

private extension ContributionSummaryContent {
    
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

#Preview {
    ContributionSummaryContent()
}
