//
//  ShowContributionSummaryIntent.swift
//  LocalPackage
//

import AppIntents
import ContributionFeature
import Foundation
import HometeDomain
import SwiftUI

/// 今月のメンバーごとのがんばりを、アプリを開かずにSiriの結果へ出す
public struct ShowContributionSummaryIntent: AppIntent {

    public static let title: LocalizedStringResource = "今月のがんばりを見る"
    public static let description = IntentDescription("今月、だれがどれくらい家事をしたかを表示します")
    /// 同居人の名前をロック画面に出さないため、端末のロックを解除してから実行する
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Dependency var environment: AppIntentEnvironment

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let summary = try await environment.perform(.showContributionSummary) {
            try await environment.houseworkService.monthlySummary(now: .now)
        }
        let dialog: IntentDialog = summary.hasData
            ? .init(.localized("今月のがんばりです"))
            : .init(.localized("今月の記録はまだありません"))
        return .result(dialog: dialog, view: ContributionSnippetContent(summary: summary))
    }

}
