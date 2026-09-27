//
//  RegisterHouseworkDraftTest.swift
//  LocalPackage
//

import HometeDomain
@testable import HouseworkFeature
import Testing

enum RegisterHouseworkDraftTest {

    struct ToggleFrequentItemCase {}
    struct QueueCurrentInputCase {}
    struct PendingEntriesCase {}
    struct RemoveCase {}
    struct HasInputCase {}
    struct SaveAsFrequentStateCase {}

    static let context = FrequentHouseworkContext(items: [
        .makeForPreview(id: "1", title: "風呂掃除", categoryId: "preset.cleaning"),
        .makeForPreview(id: "2", title: "布団干し", point: 20, categoryId: "preset.laundry"),
    ])

    static func makeInput(
        title: String,
        point: Int = 10,
        categoryId: String? = nil,
        savesAsFrequent: Bool = false,
        recurrenceInput: HouseworkRecurrenceInput = .init(kind: .none)
    ) -> RegisterHouseworkDraft.ManualEntry {
        .init(
            id: "",
            title: title,
            point: point,
            categoryId: categoryId,
            savesAsFrequent: savesAsFrequent,
            recurrenceInput: recurrenceInput
        )
    }

}

// MARK: - いつもの家事の選択

extension RegisterHouseworkDraftTest.ToggleFrequentItemCase {

    @Test("選んでいない家事をタップすると、選んだ順の末尾に加える")
    func toggleAddsItemToEnd() {
        // Arrange

        var draft = RegisterHouseworkDraft(selectedFrequentItemIds: ["2"])
        let expected = RegisterHouseworkDraft(selectedFrequentItemIds: ["2", "1"])

        // Act

        draft.toggleFrequentItem("1")

        // Assert

        #expect(draft == expected)
    }

    @Test("選んでいる家事をタップすると、選択から外す")
    func toggleRemovesSelectedItem() {
        // Arrange

        var draft = RegisterHouseworkDraft(selectedFrequentItemIds: ["1", "2"])
        let expected = RegisterHouseworkDraft(selectedFrequentItemIds: ["2"])

        // Act

        draft.toggleFrequentItem("1")

        // Assert

        #expect(draft == expected)
    }

}

// MARK: - 続けて入力する

extension RegisterHouseworkDraftTest.QueueCurrentInputCase {

    @Test("入力中の内容を積むと、名前の前後の空白を除いて末尾に加え、フォームを初期値に戻す")
    func queueCurrentInputResetsForm() {
        // Arrange

        var draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: " ゴミ出し ", point: 30))
        let expected = RegisterHouseworkDraft(
            queuedEntries: [RegisterHouseworkDraftTest.makeInput(title: "ゴミ出し", point: 30)].map {
                var entry = $0
                entry.id = "new"
                return entry
            },
            input: .initial
        )

        // Act

        draft.queueCurrentInput(id: "new")

        // Assert

        #expect(draft == expected)
    }

    @Test("名前が空のときは積まない")
    func queueCurrentInputWithBlankTitleDoesNothing() {
        // Arrange

        var draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "  "))
        let expected = draft

        // Act

        draft.queueCurrentInput(id: "new")

        // Assert

        #expect(draft == expected)
    }

    @Test(
        "名前があり、繰り返しの入力が完了していれば積める",
        arguments: [
            (" ", HouseworkRecurrenceInput(kind: .none), false),
            ("ゴミ出し", HouseworkRecurrenceInput(kind: .none), true),
            ("ゴミ出し", HouseworkRecurrenceInput(kind: .weekly, weekdays: []), false),
            ("ゴミ出し", HouseworkRecurrenceInput(kind: .weekly, weekdays: [.thursday]), true),
        ]
    )
    func canQueueCurrentInput(title: String, recurrenceInput: HouseworkRecurrenceInput, expected: Bool) {
        // Arrange

        let draft = RegisterHouseworkDraft(
            input: RegisterHouseworkDraftTest.makeInput(title: title, recurrenceInput: recurrenceInput)
        )

        // Act

        let actual = draft.canQueueCurrentInput

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - 登録予定リスト

extension RegisterHouseworkDraftTest.PendingEntriesCase {

    @Test("選択中のいつもの家事 → 続けて入力 → 入力中の順に並べる")
    func pendingEntriesAreOrderedBySource() {
        // Arrange

        var queued = RegisterHouseworkDraftTest.makeInput(title: "換気扇", point: 30, savesAsFrequent: true)
        queued.id = "queued1"
        let draft = RegisterHouseworkDraft(
            selectedFrequentItemIds: ["2", "1"],
            queuedEntries: [queued],
            input: RegisterHouseworkDraftTest.makeInput(title: " ゴミ出し ")
        )
        let expected: [PendingEntry] = [
            .init(
                source: .frequent(itemId: "2"),
                title: "布団干し",
                point: 20,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: "preset.laundry"
            ),
            .init(
                source: .frequent(itemId: "1"),
                title: "風呂掃除",
                point: 10,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: "preset.cleaning"
            ),
            .init(
                source: .queued(entryId: "queued1"),
                title: "換気扇",
                point: 30,
                recurrence: nil,
                savesAsFrequent: true,
                categoryId: nil
            ),
            .init(
                source: .editing,
                title: "ゴミ出し",
                point: 10,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: nil
            ),
        ]

        // Act

        let actual = draft.pendingEntries(context: RegisterHouseworkDraftTest.context)

        // Assert

        #expect(actual == expected)
    }

    @Test("入力中の名前が空の場合は、登録予定に含めない")
    func pendingEntriesExcludesBlankInput() {
        // Arrange

        let draft = RegisterHouseworkDraft(
            selectedFrequentItemIds: ["1"],
            input: RegisterHouseworkDraftTest.makeInput(title: " ")
        )
        let expected: [PendingEntry] = [
            .init(
                source: .frequent(itemId: "1"),
                title: "風呂掃除",
                point: 10,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: "preset.cleaning"
            ),
        ]

        // Act

        let actual = draft.pendingEntries(context: RegisterHouseworkDraftTest.context)

        // Assert

        #expect(actual == expected)
    }

    @Test("選んだあとに同居人が削除したいつもの家事は、登録予定に含めない")
    func pendingEntriesExcludesDeletedFrequentItem() {
        // Arrange

        let draft = RegisterHouseworkDraft(selectedFrequentItemIds: ["deleted"])

        // Act

        let actual = draft.pendingEntries(context: RegisterHouseworkDraftTest.context)

        // Assert

        #expect(actual == [])
    }

    @Test("繰り返しを設定した入力は、テンプレートに登録するものとして並べる")
    func pendingEntriesKeepsRecurrence() {
        // Arrange

        let draft = RegisterHouseworkDraft(
            input: RegisterHouseworkDraftTest.makeInput(
                title: "ゴミ出し",
                recurrenceInput: .init(kind: .weekly, weekdays: [.thursday])
            )
        )
        let expected: [PendingEntry] = [
            .init(
                source: .editing,
                title: "ゴミ出し",
                point: 10,
                recurrence: .weekly([.thursday]),
                savesAsFrequent: false,
                categoryId: nil
            ),
        ]

        // Act

        let actual = draft.pendingEntries(context: RegisterHouseworkDraftTest.context)

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - 取り消し

extension RegisterHouseworkDraftTest.RemoveCase {

    @Test("いつもの家事の登録予定を取り消すと、選択から外す")
    func removeFrequentEntry() {
        // Arrange

        var draft = RegisterHouseworkDraft(selectedFrequentItemIds: ["1", "2"])
        let target = PendingEntry(
            source: .frequent(itemId: "1"),
            title: "風呂掃除",
            point: 10,
            recurrence: nil,
            savesAsFrequent: false,
            categoryId: "preset.cleaning"
        )
        let expected = RegisterHouseworkDraft(selectedFrequentItemIds: ["2"])

        // Act

        draft.remove(target)

        // Assert

        #expect(draft == expected)
    }

    @Test("入力中の登録予定を取り消すと、フォームを初期値に戻す")
    func removeEditingEntry() {
        // Arrange

        var draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "ゴミ出し", point: 30))
        let target = PendingEntry(
            source: .editing,
            title: "ゴミ出し",
            point: 30,
            recurrence: nil,
            savesAsFrequent: false,
            categoryId: nil
        )
        let expected = RegisterHouseworkDraft()

        // Act

        draft.remove(target)

        // Assert

        #expect(draft == expected)
    }

}

// MARK: - 破棄の確認

extension RegisterHouseworkDraftTest.HasInputCase {

    @Test(
        "いつもの家事の選択・積んだ家事・入力中の名前のどれかがあれば、破棄の確認が要る",
        arguments: [
            (RegisterHouseworkDraft(), false),
            (RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "  ")), false),
            (RegisterHouseworkDraft(selectedFrequentItemIds: ["1"]), true),
            (RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "ゴミ出し")), true),
        ]
    )
    func hasInput(draft: RegisterHouseworkDraft, expected: Bool) {
        // Act

        let actual = draft.hasInput

        // Assert

        #expect(actual == expected)
    }

}

// MARK: - いつもの家事に保存する

extension RegisterHouseworkDraftTest.SaveAsFrequentStateCase {

    @Test("同じ名前のいつもの家事がある場合は、保存できない")
    func saveAsFrequentStateIsDuplicated() {
        // Arrange

        let draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: " 風呂掃除 "))

        // Act

        let actual = draft.saveAsFrequentState(context: RegisterHouseworkDraftTest.context, limitPolicy: .premium)

        // Assert

        #expect(actual == .duplicated)
    }

    @Test("無料プランで上限に達している場合は、名前に関係なく保存できない")
    func saveAsFrequentStateIsLimitReached() {
        // Arrange

        let items = (0 ..< 10).map { FrequentHouseworkItem.makeForPreview(id: "\($0)", title: "家事\($0)") }
        let draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "ゴミ出し"))

        // Act

        let actual = draft.saveAsFrequentState(context: .init(items: items), limitPolicy: .free)

        // Assert

        #expect(actual == .limitReached)
    }

    @Test("名前が重複せず、上限にも達していなければ保存できる")
    func saveAsFrequentStateIsAvailable() {
        // Arrange

        let draft = RegisterHouseworkDraft(input: RegisterHouseworkDraftTest.makeInput(title: "ゴミ出し"))

        // Act

        let actual = draft.saveAsFrequentState(context: RegisterHouseworkDraftTest.context, limitPolicy: .free)

        // Assert

        #expect(actual == .available)
    }

}
