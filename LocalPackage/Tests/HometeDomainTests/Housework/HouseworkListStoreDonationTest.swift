//
//  HouseworkListStoreDonationTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

/// アプリの中で家事を操作したときの、Siriやロック画面での提案のためのドネーション
@MainActor
struct HouseworkListStoreDonationTest {

    private let inputCohabitantId = "cohabitantId"
    private let inputAccount = Account(id: "own", userName: "たろう", fcmToken: nil, cohabitantId: "cohabitantId")

    @Test("家事を1件完了にすると、家事の名前でドネーションする")
    func complete_donatesHouseworkTitle() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: 1, title: "洗濯", point: 20)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                intentDonationClient: .init(donateCompleteHousework: { houseworkTitle in
                    // Assert

                    #expect(houseworkTitle == "洗濯")
                    confirmation()
                }),
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.complete(
                target: inputItem,
                now: Date(timeIntervalSince1970: 1000),
                reporter: inputAccount,
                executors: [.solo(userId: "own", point: 20)],
                effort: .normal,
                executorNames: ["たろう"],
                comment: "",
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .board
            )
        }
    }

    @Test("一括操作の一部として完了にした（通知を呼び出し側で送る）ときは、ドネーションしない")
    func complete_withoutNotify_doesNotDonate() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(id: 1, title: "洗濯", point: 20)
        let store = HouseworkListStore(
            intentDonationClient: .init(donateCompleteHousework: { _ in Issue.record() }),
            items: [.makeForTest(items: [inputItem])]
        )

        // Act

        try await store.complete(
            target: inputItem,
            now: Date(timeIntervalSince1970: 1000),
            reporter: inputAccount,
            executors: [.solo(userId: "own", point: 20)],
            effort: .normal,
            executorNames: ["たろう"],
            comment: "",
            cohabitantId: inputCohabitantId,
            isRegistered: true,
            step: .board,
            notify: false
        )
    }

    @Test("初めてありがとうを記録すると、ドネーションする")
    func sendThanks_first_donates() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "partner",
            executedAt: .distantPast
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                intentDonationClient: .init(donateSendThanks: {
                    // Assert

                    confirmation()
                }),
                items: [.makeForTest(items: [inputItem])]
            )

            // Act

            try await store.sendThanks(
                target: inputItem,
                sender: inputAccount,
                comment: nil,
                now: Date(timeIntervalSince1970: 1000),
                cohabitantId: inputCohabitantId,
                step: .board
            )
        }
    }

    @Test("送ったありがとうのコメントを直したときは、ドネーションしない")
    func sendThanks_edit_doesNotDonate() async throws {
        // Arrange

        let inputItem = HouseworkItem.makeForTest(
            id: 1,
            state: .completed,
            executorId: "partner",
            executedAt: .distantPast,
            thanks: ["own": .init(comment: "ありがとう", sentAt: .distantPast)]
        )
        let store = HouseworkListStore(
            intentDonationClient: .init(donateSendThanks: { Issue.record() }),
            items: [.makeForTest(items: [inputItem])]
        )

        // Act

        try await store.sendThanks(
            target: inputItem,
            sender: inputAccount,
            comment: "いつもありがとう",
            now: Date(timeIntervalSince1970: 1000),
            cohabitantId: inputCohabitantId,
            step: .thanks
        )
    }

}
