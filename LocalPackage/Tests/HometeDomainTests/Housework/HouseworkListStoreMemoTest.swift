//
//  HouseworkListStoreMemoTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct HouseworkListStoreMemoTest {

    private let inputCohabitantId = "cohabitantId"
    private let inputMemo = HouseworkMemo(
        text: "スーパーで",
        checklist: [.init(id: "milk", title: "牛乳", isChecked: false)]
    )

    @Test("登録済みの家事のメモを保存すると、メモのフィールドだけを書き換え、同居人には通知しない")
    func updateMemo_registered_updatesOnlyMemo() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { _, _ in Issue.record() },
                    updateMemoHandler: { houseworkId, memo, cohabitantId in
                        // Assert

                        #expect(houseworkId == inputHouseworkItem.id)
                        #expect(memo == inputMemo)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in Issue.record() },
                items: [.makeForTest(items: [inputHouseworkItem])]
            )

            // Act

            try await store.updateMemo(
                target: inputHouseworkItem,
                memo: inputMemo,
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .detail
            )
        }
    }

    @Test("テンプレートから表示しているだけの家事のメモを保存すると、作成日時を付けてドキュメントごと作る")
    func updateMemo_notRegistered_insertsItem() async throws {
        // Arrange

        let inputNow = Date(timeIntervalSince1970: 1000)
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: .distantPast,
            expiredAt: .distantPast,
            templateHouseworkItemId: .init(id: "template")
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in
                        // Assert

                        let expected = HouseworkItem.makeForTest(
                            id: 1,
                            indexedDate: .distantPast,
                            expiredAt: .distantPast,
                            templateHouseworkItemId: .init(id: "template"),
                            createdAt: inputNow,
                            memo: inputMemo
                        )
                        #expect(item == expected)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    },
                    updateMemoHandler: { _, _, _ in Issue.record() }
                ),
                now: { inputNow },
                items: []
            )

            // Act

            try await store.updateMemo(
                target: inputHouseworkItem,
                memo: inputMemo,
                cohabitantId: inputCohabitantId,
                isRegistered: false,
                step: .detail
            )
        }
    }

    @Test("メモを保存すると、Analyticsにメモの編集を送る")
    func updateMemo_logsEditMemo() async throws {
        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(updateMemoHandler: { _, _, _ in }),
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        try await store.updateMemo(
            target: inputHouseworkItem,
            memo: inputMemo,
            cohabitantId: inputCohabitantId,
            isRegistered: true,
            step: .detail
        )

        // Assert

        #expect(logger.value == [.housework(.editMemo(step: .detail, isSuccess: true))])
    }

    @Test(
        "画面を開いている間に同居人が完了・やらないにした家事は、メモを保存せずnotEditableを返す",
        arguments: [HouseworkState.completed, .notTodo]
    )
    func updateMemo_notEditable_throws(state: HouseworkState) async {
        // Arrange

        let inputIndexedDate = Date(timeIntervalSince1970: 0)
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1, indexedDate: inputIndexedDate)
        let store = HouseworkListStore(
            houseworkClient: .init(
                insertOrUpdateItemHandler: { _, _ in Issue.record() },
                updateMemoHandler: { _, _, _ in Issue.record() }
            ),
            items: [.makeForTest(items: [.makeForTest(id: 1, indexedDate: inputIndexedDate, state: state)])]
        )

        // Act & Assert

        await #expect(throws: HouseworkMemoError.notEditable) {
            try await store.updateMemo(
                target: inputHouseworkItem,
                memo: inputMemo,
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .detail
            )
        }
    }

    @Test("チェックを切り替えると、同居人が付けたチェックを消さないよう、最新のメモに対して切り替える")
    func toggleMemoChecklistItem_togglesLatestMemo() async throws {
        // Arrange

        let inputIndexedDate = Date(timeIntervalSince1970: 0)
        let openedMemo = HouseworkMemo(
            text: "",
            checklist: [
                .init(id: "milk", title: "牛乳", isChecked: false),
                .init(id: "egg", title: "卵", isChecked: false),
            ]
        )
        let latestMemo = HouseworkMemo(
            text: "",
            checklist: [
                .init(id: "milk", title: "牛乳", isChecked: false),
                .init(id: "egg", title: "卵", isChecked: true),
            ]
        )
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1, indexedDate: inputIndexedDate, memo: openedMemo)
        let latestItem = HouseworkItem.makeForTest(id: 1, indexedDate: inputIndexedDate, memo: latestMemo)

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(updateMemoHandler: { _, memo, _ in
                    // Assert

                    let expected = HouseworkMemo(
                        text: "",
                        checklist: [
                            .init(id: "milk", title: "牛乳", isChecked: true),
                            .init(id: "egg", title: "卵", isChecked: true),
                        ]
                    )
                    #expect(memo == expected)
                    confirmation()
                }),
                analyticsClient: .init(log: { _ in Issue.record() }),
                items: [.makeForTest(items: [latestItem])]
            )

            // Act

            try await store.toggleMemoChecklistItem(
                target: inputHouseworkItem,
                itemId: "milk",
                cohabitantId: inputCohabitantId,
                isRegistered: true
            )
        }
    }

    @Test("メモを保存すると、シートを開いている間に同居人が付けたチェックを戻さない")
    func updateMemo_keepsLatestCheckState() async throws {
        // Arrange

        let inputIndexedDate = Date(timeIntervalSince1970: 0)
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1, indexedDate: inputIndexedDate)
        let latestItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputIndexedDate,
            memo: .init(text: "", checklist: [.init(id: "milk", title: "牛乳", isChecked: true)])
        )

        try await confirmation { confirmation in
            let store = HouseworkListStore(
                houseworkClient: .init(updateMemoHandler: { _, memo, _ in
                    // Assert

                    let expected = HouseworkMemo(
                        text: "スーパーで",
                        checklist: [.init(id: "milk", title: "牛乳", isChecked: true)]
                    )
                    #expect(memo == expected)
                    confirmation()
                }),
                items: [.makeForTest(items: [latestItem])]
            )

            // Act

            try await store.updateMemo(
                target: inputHouseworkItem,
                memo: inputMemo,
                cohabitantId: inputCohabitantId,
                isRegistered: true,
                step: .detail
            )
        }
    }

    @Test("メモの保存に失敗すると、Analyticsに失敗を送ってエラーを返す")
    func updateMemo_failure_logsFailure() async {
        // Arrange

        struct SaveError: Error {}
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let logger = TestBox<[AnalyticsEvent]>(value: [])
        let store = HouseworkListStore(
            houseworkClient: .init(updateMemoHandler: { _, _, _ in throw SaveError() }),
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            items: [.makeForTest(items: [inputHouseworkItem])]
        )

        // Act

        try? await store.updateMemo(
            target: inputHouseworkItem,
            memo: inputMemo,
            cohabitantId: inputCohabitantId,
            isRegistered: true,
            step: .detail
        )

        // Assert

        #expect(logger.value == [.housework(.editMemo(step: .detail, isSuccess: false))])
    }

}
