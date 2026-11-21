//
//  AppIntentEnvironment+ContributionSummary.swift
//  LocalPackage
//

import Foundation
import HometeDomain

public extension AppIntentEnvironment {

    /// 今月のメンバーごとのがんばりを取得し、結果を`app_intent`イベントで送る
    /// - Note: 結果をSiriに出すViewはSwiftUIで描くため、Intent（`ShowContributionSummaryIntent`）はUIPackageの`HometeAppIntentsUI`に置いている
    nonisolated(nonsending) func monthlyContributionSummary(now: Date) async throws -> ContributionMonthlySummary {
        try await perform(.showContributionSummary) {
            try await houseworkService.monthlySummary(now: now)
        }
    }

}
