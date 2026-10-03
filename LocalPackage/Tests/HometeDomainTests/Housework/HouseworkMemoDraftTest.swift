//
//  HouseworkMemoDraftTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

enum HouseworkMemoDraftTest {

    struct MemoCase {}
    struct CanSaveCase {}
    struct ChecklistCase {}

}

extension HouseworkMemoDraftTest.MemoCase {

    @Test("保存するメモは、前後の空白・改行を除き、項目名が空の項目を除いたもの")
    func memo_trimsAndDropsEmptyItems() {
        // Arrange

        var draft = HouseworkMemoDraft(original: .init(
            text: "",
            checklist: [.init(id: "milk", title: "牛乳", isChecked: true)]
        ))
        draft.text = "  スーパーで\n"
        draft.addItem(id: "empty")
        draft.addItem(id: "egg")

        // Act

        draft.updateTitle(" 卵 ", of: "egg")

        // Assert

        let expected = HouseworkMemo(
            text: "スーパーで",
            checklist: [
                .init(id: "milk", title: "牛乳", isChecked: true),
                .init(id: "egg", title: "卵", isChecked: false),
            ]
        )
        #expect(draft.memo == expected)
    }

}

extension HouseworkMemoDraftTest.CanSaveCase {

    @Test("メモを書いていない家事で、空白しか入力していなければ保存できない")
    func canSave_newBlankMemo_returnsFalse() {
        // Arrange

        var draft = HouseworkMemoDraft(original: nil)

        // Act

        draft.text = "  "

        // Assert

        #expect(draft.canSave(.free) == false)
    }

    @Test("書いたメモをすべて消すと、空のメモとして保存できる")
    func canSave_clearedMemo_returnsTrue() {
        // Arrange

        var draft = HouseworkMemoDraft(original: .init(text: "スーパーで", checklist: []))

        // Act

        draft.text = ""

        // Assert

        #expect(draft.canSave(.free) == true)
    }

    @Test("編集前から変わっていなければ保存できない")
    func canSave_noChanges_returnsFalse() {
        // Arrange

        let draft = HouseworkMemoDraft(original: .init(text: "スーパーで", checklist: []))

        // Act

        let actual = draft.canSave(.free)

        // Assert

        #expect(actual == false)
    }

    @Test(
        "無料プランは、テキストと項目名（牛乳: 2文字）の合計が200文字を超えると保存できない",
        arguments: [
            (198, true),
            (199, false),
        ]
    )
    func canSave_overFreeLimit_returnsFalse(textLength: Int, expected: Bool) {
        // Arrange

        var draft = HouseworkMemoDraft(original: nil)
        draft.addItem(id: "milk")
        draft.updateTitle("牛乳", of: "milk")

        // Act

        draft.text = String(repeating: "あ", count: textLength)

        // Assert

        #expect(draft.canSave(.free) == expected)
    }

}

extension HouseworkMemoDraftTest.ChecklistCase {

    @Test("項目を削除すると、その項目だけがなくなる")
    func removeItem_removesOnlyTarget() {
        // Arrange

        var draft = HouseworkMemoDraft(original: .init(
            text: "",
            checklist: [
                .init(id: "milk", title: "牛乳", isChecked: false),
                .init(id: "egg", title: "卵", isChecked: true),
            ]
        ))

        // Act

        draft.removeItem(id: "milk")

        // Assert

        let expected = HouseworkMemo(text: "", checklist: [.init(id: "egg", title: "卵", isChecked: true)])
        #expect(draft.memo == expected)
    }

    @Test("項目が100個あると、それ以上追加できない")
    func addItem_atLimit_doesNotAdd() {
        // Arrange

        var draft = HouseworkMemoDraft(original: .init(
            text: "",
            checklist: (0 ..< 100).map { .init(id: "\($0)", title: "項目", isChecked: false) }
        ))

        // Act

        draft.addItem(id: "new")

        // Assert

        #expect(draft.checklist.count == 100)
    }

}
