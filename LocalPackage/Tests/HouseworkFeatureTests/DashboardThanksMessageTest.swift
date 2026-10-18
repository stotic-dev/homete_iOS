//
//  DashboardThanksMessageTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct DashboardThanksMessageTest {

    private let thanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 2, executorNames: ["はなこ"])
    private let noThanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 0, executorNames: [])
    private let receivedThanks = ReceivedThanksSummary(
        count: 1,
        senderNames: ["はなこ"],
        latestSentAt: .previewDate(year: 2026, month: 10, day: 6, hour: 7)
    )

    @Test("感謝の促しと届いたありがとうの両方があれば、感謝の促しだけを出す")
    func select_both_returnsThanksPrompt() {
        // Act
        let actual = DashboardThanksMessage.select(thanksPrompt: thanksPrompt, receivedThanks: receivedThanks)

        // Assert
        #expect(actual == .thanksPrompt(thanksPrompt))
    }

    @Test("感謝の促しがなければ、届いたありがとうを出す")
    func select_onlyReceivedThanks_returnsReceivedThanks() {
        // Act
        let actual = DashboardThanksMessage.select(thanksPrompt: noThanksPrompt, receivedThanks: receivedThanks)

        // Assert
        #expect(actual == .receivedThanks(receivedThanks))
    }

    @Test(
        "出せるものがなければ何も出さない",
        arguments: [
            ReceivedThanksSummary?.none,
            ReceivedThanksSummary(count: 0, senderNames: [], latestSentAt: nil),
        ]
    )
    func select_nothing_returnsNil(receivedThanks: ReceivedThanksSummary?) {
        // Act
        let actual = DashboardThanksMessage.select(thanksPrompt: noThanksPrompt, receivedThanks: receivedThanks)

        // Assert
        #expect(actual == nil)
    }

}
