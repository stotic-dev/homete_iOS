//
//  HouseworkMemoLimitPolicyTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct HouseworkMemoLimitPolicyTest {

    @Test(
        "新しく書くメモは、プランの文字数上限以内なら保存できる",
        arguments: [
            (false, 200, true),
            (false, 201, false),
            (true, 5000, true),
            (true, 5001, false),
        ]
    )
    func canSave_newMemo_withinCharacterLimit(isPremium: Bool, characterCount: Int, expected: Bool) {
        // Arrange

        let policy = HouseworkMemoLimitPolicy(isPremium: isPremium)
        let memo = HouseworkMemo(text: String(repeating: "あ", count: characterCount), checklist: [])

        // Act

        let actual = policy.canSave(memo, original: nil)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "上限を超えたメモでも、編集前より文字数が増えていなければ保存できる",
        arguments: [
            (300, true),
            (299, true),
            (301, false),
        ]
    )
    func canSave_overLimit_allowsWhenNotIncreased(characterCount: Int, expected: Bool) {
        // Arrange

        let policy = HouseworkMemoLimitPolicy(isPremium: false)
        let original = HouseworkMemo(text: String(repeating: "あ", count: 300), checklist: [])
        let memo = HouseworkMemo(text: String(repeating: "い", count: characterCount), checklist: [])

        // Act

        let actual = policy.canSave(memo, original: original)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "チェックリストは、プランに関係なく100項目まで保存できる",
        arguments: [
            (false, 100, true),
            (false, 101, false),
            (true, 100, true),
            (true, 101, false),
        ]
    )
    func canSave_newMemo_withinChecklistLimit(isPremium: Bool, itemCount: Int, expected: Bool) {
        // Arrange

        let policy = HouseworkMemoLimitPolicy(isPremium: isPremium)
        let memo = HouseworkMemo(
            text: "",
            checklist: (0 ..< itemCount).map { .init(id: "\($0)", title: "", isChecked: false) }
        )

        // Act

        let actual = policy.canSave(memo, original: nil)

        // Assert

        #expect(actual == expected)
    }

    @Test("項目数が上限を超えていても、編集前より増えていなければ保存できる")
    func canSave_overChecklistLimit_allowsWhenNotIncreased() {
        // Arrange

        let policy = HouseworkMemoLimitPolicy(isPremium: false)
        let checklist: [HouseworkMemoChecklistItem] = (0 ..< 101).map {
            .init(id: "\($0)", title: "", isChecked: false)
        }
        let original = HouseworkMemo(text: "", checklist: checklist)
        let memo = HouseworkMemo(text: "", checklist: checklist.map { .init(id: $0.id, title: "", isChecked: true) })

        // Act

        let actual = policy.canSave(memo, original: original)

        // Assert

        #expect(actual == true)
    }

}
