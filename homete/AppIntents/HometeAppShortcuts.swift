//
//  HometeAppShortcuts.swift
//  homete
//

import AppIntents
import HometeAppIntents

/// `HometeAppIntents`パッケージのApp Intentを、アプリのメタデータに含める
struct HometeAppIntentsPackageRoot: AppIntentsPackage {

    static var includedPackages: [any AppIntentsPackage.Type] {
        [HometeAppIntentsPackage.self]
    }

}

/// Siri・Spotlight・ショートカットApp・アクションボタンから、設定なしで使えるショートカット
///
/// フレーズは開発言語（英語）で書き、日本語は`AppShortcuts.xcstrings`に入れる。
/// どのフレーズにもアプリ名を入れる必要がある（App Shortcutsの制約）。
struct HometeAppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteHouseworkIntent(),
            phrases: [
                "Complete \(\.$housework) in \(.applicationName)",
                "Finish \(\.$housework) in \(.applicationName)",
                "Complete a chore in \(.applicationName)",
            ],
            shortTitle: "Complete Chore",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: RecordHouseworkIntent(),
            phrases: [
                "Log a chore in \(.applicationName)",
                "Record a chore in \(.applicationName)",
            ],
            shortTitle: "Log Chore",
            systemImageName: "pencil.circle"
        )
        AppShortcut(
            intent: RegisterHouseworkIntent(),
            phrases: [
                "Add a chore in \(.applicationName)",
                "Add a chore to do in \(.applicationName)",
            ],
            shortTitle: "Add Chore",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: SendThanksIntent(),
            phrases: [
                "Say thanks in \(.applicationName)",
                "Send thanks in \(.applicationName)",
            ],
            shortTitle: "Say Thanks",
            systemImageName: "heart"
        )
        AppShortcut(
            intent: ShowContributionSummaryIntent(),
            phrases: [
                "Show this month in \(.applicationName)",
                "Show this month's effort in \(.applicationName)",
            ],
            shortTitle: "This Month",
            systemImageName: "chart.pie"
        )
        AppShortcut(
            intent: OpenContributionAnalyticsIntent(),
            phrases: [
                "Open analytics in \(.applicationName)",
            ],
            shortTitle: "Analytics",
            systemImageName: "chart.bar"
        )
    }

}
