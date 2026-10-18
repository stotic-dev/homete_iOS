//
//  OpenContributionAnalyticsIntent.swift
//  LocalPackage
//

import AppIntents
import HometeDomain

/// アプリを開いて、がんばりの分析画面を出す
public struct OpenContributionAnalyticsIntent: AppIntent {

    public static let title: LocalizedStringResource = "がんばりの分析を開く"
    public static let description = IntentDescription("アプリを開いて、家事の記録の分析画面を出します")
    public static let openAppWhenRun = true

    @Dependency var environment: AppIntentEnvironment
    @Dependency var pendingRouteStore: PendingRouteStore

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        // ダッシュボードの読み込みを待ってから開くため、開く画面を退避してダッシュボードに任せる
        pendingRouteStore.store(.contributionAnalytics)
        environment.analyticsClient.log(.appIntent(.openContributionAnalytics, result: .success))
        return .result()
    }

}
