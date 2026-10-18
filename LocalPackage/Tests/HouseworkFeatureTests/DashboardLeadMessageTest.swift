//
//  DashboardLeadMessageTest.swift
//  LocalPackage
//

@testable import HouseworkFeature
import Testing

struct DashboardLeadMessageTest {

    @Test("ありがとうを送っていない家事があれば、ねぎらいの代わりに感謝の促しを出す")
    func select_thanksPrompt_returnsThanksPrompt() {
        // Arrange
        let thanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 2, executorNames: ["はなこ"])

        // Act
        let actual = DashboardLeadMessage.select(thanksPrompt: thanksPrompt)

        // Assert
        #expect(actual == .thanksPrompt(thanksPrompt))
    }

    @Test("ありがとうを送っていない家事がなければ、ねぎらいを出す")
    func select_noThanksPrompt_returnsEncouragement() {
        // Arrange
        let thanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 0, executorNames: [])

        // Act
        let actual = DashboardLeadMessage.select(thanksPrompt: thanksPrompt)

        // Assert
        #expect(actual == .encouragement)
    }

}
