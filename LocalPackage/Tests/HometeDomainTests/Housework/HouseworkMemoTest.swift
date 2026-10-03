//
//  HouseworkMemoTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

enum HouseworkMemoTest {

    struct CharacterCountCase {}
    struct ToggledCase {}
    struct HasContentCase {}
    struct MergingCheckStateCase {}

}

extension HouseworkMemoTest.CharacterCountCase {

    @Test("文字数は、テキストとチェックリストの項目名の文字数を合計したもの")
    func characterCount_sumsTextAndChecklistTitles() {
        // Arrange

        let memo = HouseworkMemo(
            text: "スーパーで",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: false),
                .init(id: "2", title: "卵", isChecked: true),
            ]
        )

        // Act

        let actual = memo.characterCount

        // Assert

        #expect(actual == 8)
    }

    @Test("絵文字は見た目どおり1文字として数える")
    func characterCount_countsEmojiAsOneCharacter() {
        // Arrange

        let memo = HouseworkMemo(text: "👨‍👩‍👧", checklist: [])

        // Act

        let actual = memo.characterCount

        // Assert

        #expect(actual == 1)
    }

}

extension HouseworkMemoTest.ToggledCase {

    @Test("指定した項目のチェックだけが切り替わる")
    func toggled_togglesOnlyTargetItem() {
        // Arrange

        let memo = HouseworkMemo(
            text: "テキスト",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: false),
                .init(id: "2", title: "卵", isChecked: true),
            ]
        )

        // Act

        let actual = memo.toggled("2")

        // Assert

        let expected = HouseworkMemo(
            text: "テキスト",
            checklist: [
                .init(id: "1", title: "牛乳", isChecked: false),
                .init(id: "2", title: "卵", isChecked: false),
            ]
        )
        #expect(actual == expected)
    }

}

extension HouseworkMemoTest.HasContentCase {

    @Test(
        "一度も書いていないメモと、書いて消したメモは内容なしとして扱う",
        arguments: [
            (HouseworkMemo?.none, false),
            (HouseworkMemo.empty, false),
            (HouseworkMemo(text: "テキスト", checklist: []), true),
            (HouseworkMemo(text: "", checklist: [.init(id: "1", title: "牛乳", isChecked: false)]), true),
        ]
    )
    func hasContent(memo: HouseworkMemo?, expected: Bool) {
        // Act

        let actual = memo.hasContent

        // Assert

        #expect(actual == expected)
    }

}

extension HouseworkMemoTest.MergingCheckStateCase {

    @Test("同じ項目のチェック状態だけを最新に合わせ、名前・テキスト・追加した項目は編集した内容のまま")
    func mergingCheckState_usesLatestCheckState() {
        // Arrange

        let edited = HouseworkMemo(
            text: "編集後",
            checklist: [
                .init(id: "milk", title: "牛乳2本", isChecked: false),
                .init(id: "new", title: "卵", isChecked: false),
            ]
        )
        let latest = HouseworkMemo(
            text: "編集前",
            checklist: [
                .init(id: "milk", title: "牛乳", isChecked: true),
                .init(id: "removed", title: "パン", isChecked: true),
            ]
        )

        // Act

        let actual = edited.mergingCheckState(from: latest)

        // Assert

        let expected = HouseworkMemo(
            text: "編集後",
            checklist: [
                .init(id: "milk", title: "牛乳2本", isChecked: true),
                .init(id: "new", title: "卵", isChecked: false),
            ]
        )
        #expect(actual == expected)
    }

}
