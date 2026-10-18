//
//  DashboardLeadMessageTest.swift
//  LocalPackage
//

@testable import HouseworkFeature
import Testing

struct DashboardLeadMessageTest {

    private let noThanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 0, executorNames: [])
    private let noPastThanksPrompt = PastThanksPromptSummary(dailyItems: [], notSentCount: 0, executorNames: [])

    @Test("今日の家事にありがとうを送っていないものがあれば、過去の促しより先に感謝の促しを出す")
    func select_thanksPrompt_returnsThanksPrompt() {
        // Arrange
        let thanksPrompt = ThanksPromptSummary(thankableItems: [], notSentCount: 2, executorNames: ["はなこ"])
        let pastThanksPrompt = PastThanksPromptSummary(dailyItems: [], notSentCount: 1, executorNames: ["はなこ"])

        // Act
        let actual = DashboardLeadMessage.select(
            thanksPrompt: thanksPrompt,
            pastThanksPrompt: pastThanksPrompt,
            canShowPastThanksPrompt: true
        )

        // Assert
        #expect(actual == .thanksPrompt(thanksPrompt))
    }

    @Test("今日の促しがなく、過去の家事にありがとうを送っていないものがあれば、ねぎらいの代わりに過去の促しを出す")
    func select_pastThanksPrompt_returnsPastThanksPrompt() {
        // Arrange
        let pastThanksPrompt = PastThanksPromptSummary(dailyItems: [], notSentCount: 3, executorNames: ["はなこ"])

        // Act
        let actual = DashboardLeadMessage.select(
            thanksPrompt: noThanksPrompt,
            pastThanksPrompt: pastThanksPrompt,
            canShowPastThanksPrompt: true
        )

        // Assert
        #expect(actual == .pastThanksPrompt(pastThanksPrompt))
    }

    @Test("過去の促しを今日の上限まで出し切っていたら、ねぎらいを出す")
    func select_pastThanksPromptExhausted_returnsEncouragement() {
        // Arrange
        let pastThanksPrompt = PastThanksPromptSummary(dailyItems: [], notSentCount: 3, executorNames: ["はなこ"])

        // Act
        let actual = DashboardLeadMessage.select(
            thanksPrompt: noThanksPrompt,
            pastThanksPrompt: pastThanksPrompt,
            canShowPastThanksPrompt: false
        )

        // Assert
        #expect(actual == .encouragement)
    }

    @Test("ありがとうを送っていない家事がなければ、ねぎらいを出す")
    func select_noThanksPrompt_returnsEncouragement() {
        // Act
        let actual = DashboardLeadMessage.select(
            thanksPrompt: noThanksPrompt,
            pastThanksPrompt: noPastThanksPrompt,
            canShowPastThanksPrompt: true
        )

        // Assert
        #expect(actual == .encouragement)
    }

}
