//
//  HouseworkCommandUseCaseTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

/// 家事の完了・ありがとうの書き込みと、それに伴うAnalytics・同居人への通知
struct HouseworkCommandUseCaseTest {

    private struct WriteError: Error {}

    private let now = Date.previewDate(year: 2026, month: 10, day: 12, hour: 9)
    private let today = Date.previewDate(year: 2026, month: 10, day: 12)
    private let own = Account(id: "own", userName: "たろう", cohabitantId: "cohabitant")

}

// MARK: - 家事の完了

extension HouseworkCommandUseCaseTest {

    @Test("通知の送信を待つ指定なら、同居人への完了通知を送り終えてから返す")
    func complete_awaiting_notifiesBeforeReturning() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: "laundry", indexedDate: today, title: "洗濯", point: 20)
        let expectedContent = PushNotificationContent(
            message: .completed(executorName: "たろう", houseworkTitle: "洗濯", comment: ""),
            completedData: .init(houseworkDate: today)
        )

        // Act

        try await confirmation { confirmation in
            let sut = makeSUT(
                pushNotificationClient: .init { cohabitantId, content in
                    // Assert

                    #expect(cohabitantId == "cohabitant")
                    #expect(content == expectedContent)
                    confirmation()
                }
            )
            // 送信を待たずに返すと、confirmationを抜けた後に通知が送られて数に入らない
            try await sut.complete(
                current: inputItem,
                now: now,
                reporter: own,
                executors: [.solo(userId: "own", point: 20)],
                effort: .normal,
                executorNames: ["たろう"],
                comment: "",
                cohabitantId: "cohabitant",
                isRegistered: true,
                step: .appIntent,
                delivery: .awaiting
            )
        }
    }

    @Test("通知を呼び出し側で送る指定なら、書き込みとAnalyticsだけ行い、完了通知は送らない")
    func complete_withoutNotify() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: "laundry", indexedDate: today, title: "洗濯", point: 20)

        // Act

        try await confirmation(expectedCount: 2) { confirmation in
            let sut = makeSUT(
                houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
                    // Assert

                    confirmation()
                }),
                pushNotificationClient: .init { _, _ in Issue.record("通知しない") },
                log: { event in
                    // Assert

                    #expect(event == .housework(.complete(
                        step: .board,
                        executorType: .ownOnly,
                        effort: .normal,
                        isSuccess: true
                    )))
                    confirmation()
                }
            )
            try await sut.complete(
                current: inputItem,
                now: now,
                reporter: own,
                executors: [.solo(userId: "own", point: 20)],
                effort: .normal,
                executorNames: ["たろう"],
                comment: "",
                cohabitantId: "cohabitant",
                isRegistered: true,
                step: .board,
                notify: false,
                delivery: .awaiting
            )
        }
    }

    @Test("書き込みに失敗したら、失敗のAnalyticsを送ってエラーを投げ、完了通知は送らない")
    func complete_writeFailure() async {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: "laundry", indexedDate: today, title: "洗濯", point: 20)

        await confirmation { confirmation in
            let sut = makeSUT(
                houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in throw WriteError() }),
                pushNotificationClient: .init { _, _ in Issue.record("通知しない") },
                log: { event in
                    // Assert

                    #expect(event == .housework(.complete(
                        step: .appIntent,
                        executorType: .ownOnly,
                        effort: .normal,
                        isSuccess: false
                    )))
                    confirmation()
                }
            )

            // Act

            await #expect(throws: WriteError.self) {
                try await sut.complete(
                    current: inputItem,
                    now: now,
                    reporter: own,
                    executors: [.solo(userId: "own", point: 20)],
                    effort: .normal,
                    executorNames: ["たろう"],
                    comment: "",
                    cohabitantId: "cohabitant",
                    isRegistered: true,
                    step: .appIntent,
                    delivery: .awaiting
                )
            }
        }
    }

}

// MARK: - ありがとう

extension HouseworkCommandUseCaseTest {

    @Test("未完了に戻された家事には、ありがとうを記録しない")
    func sendThanks_incomplete() async throws {
        // Arrange

        let sut = makeSUT(
            houseworkClient: .init(upsertThanksHandler: { _, _, _, _ in Issue.record("書き込まない") })
        )

        // Act

        let actual = try await sut.sendThanks(
            current: .makeForTest(id: "dish", indexedDate: today, title: "皿洗い"),
            sender: own,
            comment: "助かった",
            now: now,
            cohabitantId: "cohabitant",
            step: .appIntent,
            delivery: .awaiting
        )

        // Assert

        #expect(actual == false)
    }

    @Test("コメントなしで送った後にコメントを書き足したら、最初に送った日時のまま記録し、相手に通知する")
    func sendThanks_addComment() async throws {
        // Arrange

        let sentAt = Date.previewDate(year: 2026, month: 10, day: 12, hour: 8)
        let inputItem = HouseworkItem.makeForTest(
            id: "dish",
            indexedDate: today,
            title: "皿洗い",
            state: .completed,
            executorId: "partner",
            executedAt: sentAt,
            thanks: ["own": .init(comment: nil, sentAt: sentAt)]
        )
        let expectedContent = PushNotificationContent.thanksMessage(
            senderName: "たろう",
            houseworkTitle: "皿洗い",
            houseworkId: "dish",
            comment: "助かった"
        )

        // Act

        let actual = try await confirmation(expectedCount: 2) { confirmation in
            let sut = makeSUT(
                houseworkClient: .init(upsertThanksHandler: { _, _, thanks, _ in
                    // Assert

                    #expect(thanks == HouseworkThanks(comment: "助かった", sentAt: sentAt))
                    confirmation()
                }),
                pushNotificationClient: .init { _, content in
                    // Assert

                    #expect(content == expectedContent)
                    confirmation()
                }
            )
            return try await sut.sendThanks(
                current: inputItem,
                sender: own,
                comment: "助かった",
                now: now,
                cohabitantId: "cohabitant",
                step: .thanks,
                delivery: .awaiting
            )
        }

        // Assert

        // 初めての記録ではなく、コメントの書き足し
        #expect(actual == false)
    }

}

private extension HouseworkCommandUseCaseTest {

    func makeSUT(
        houseworkClient: HouseworkClient = .previewValue,
        pushNotificationClient: CohabitantPushNotificationClient = .previewValue,
        log: @escaping @Sendable (AnalyticsEvent) -> Void = { _ in }
    ) -> HouseworkCommandUseCase {
        .init(
            houseworkClient: houseworkClient,
            cohabitantPushNotificationClient: pushNotificationClient,
            analyticsClient: .init(log: log),
            dailyCompletionReminderUseCase: .init(client: .previewValue),
            calendar: .japanese
        )
    }

}
