//
//  IntentDonationClient+Live.swift
//  LocalPackage
//

import AppIntents
import HometeDomain

public extension IntentDonationClient {

    /// Intentを組み立てて`donate()`する
    /// - Note: ドネーションの失敗は操作の失敗にしない（提案に出にくくなるだけ）
    static let liveValue = IntentDonationClient(
        donateCompleteHousework: { houseworkTitle in
            donate(CompleteHouseworkIntent(housework: .init(id: houseworkTitle)))
        },
        donateSendThanks: {
            donate(SendThanksIntent())
        },
        donateContributionSummary: {
            donate(ShowContributionSummaryIntent())
        },
        updateHouseworkTitles: {
            HometeAppIntentsConfigurator.updateAppShortcutParameters()
        }
    )

}

private extension IntentDonationClient {

    static func donate(_ intent: some AppIntent) {
        Task {
            do {
                _ = try await intent.donate()
            } catch {
                print("failed to donate app intent: \(error)")
            }
        }
    }

}
