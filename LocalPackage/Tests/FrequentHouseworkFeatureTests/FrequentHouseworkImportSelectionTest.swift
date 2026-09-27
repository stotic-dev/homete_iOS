//
//  FrequentHouseworkImportSelectionTest.swift
//  LocalPackage
//

@testable import FrequentHouseworkFeature
import HometeDomain
import Testing

enum FrequentHouseworkImportSelectionTest {

    struct CheckedTitlesCase {}
    struct TogglingCase {}
    struct ImportTargetsCase {}

    static let candidates: [FrequentHouseworkImportCandidate] = [
        .init(title: "風呂掃除", point: 10, isAlreadyRegistered: false),
        .init(title: "洗濯", point: 20, isAlreadyRegistered: true),
        .init(title: "ゴミ出し", point: 10, isAlreadyRegistered: false),
    ]

}

extension FrequentHouseworkImportSelectionTest.CheckedTitlesCase {

    @Test("登録済みの候補は、選んでいなくてもチェック済みとして扱う")
    func checkedTitlesContainsAlreadyRegistered() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除"])
        let expected: Set = ["風呂掃除", "洗濯"]

        // Act

        let actual = selection.checkedTitles(in: FrequentHouseworkImportSelectionTest.candidates)

        // Assert

        #expect(actual == expected)
    }

}

extension FrequentHouseworkImportSelectionTest.TogglingCase {

    @Test("選んでいない候補をタップすると、選択に加える")
    func togglingAddsCandidate() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除"])
        let candidate = FrequentHouseworkImportCandidate(title: "ゴミ出し", point: 10, isAlreadyRegistered: false)
        let expected = FrequentHouseworkImportSelection.ToggleResult.changed(
            .init(selectedTitles: ["風呂掃除", "ゴミ出し"])
        )

        // Act

        let actual = selection.toggling(candidate, remainingCount: nil)

        // Assert

        #expect(actual == expected)
    }

    @Test("選んでいる候補をタップすると、選択から外す")
    func togglingRemovesCandidate() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除", "ゴミ出し"])
        let candidate = FrequentHouseworkImportCandidate(title: "ゴミ出し", point: 10, isAlreadyRegistered: false)
        let expected = FrequentHouseworkImportSelection.ToggleResult.changed(.init(selectedTitles: ["風呂掃除"]))

        // Act

        let actual = selection.toggling(candidate, remainingCount: nil)

        // Assert

        #expect(actual == expected)
    }

    @Test("残り件数まで選んでいる状態で新しく選ぼうとすると、上限に達したと返す")
    func togglingOverRemainingCountIsLimitReached() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除"])
        let candidate = FrequentHouseworkImportCandidate(title: "ゴミ出し", point: 10, isAlreadyRegistered: false)

        // Act

        let actual = selection.toggling(candidate, remainingCount: 1)

        // Assert

        #expect(actual == .limitReached)
    }

    @Test("残り件数まで選んでいても、選択を外すのはできる")
    func togglingRemovesCandidateEvenWhenLimitReached() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除"])
        let candidate = FrequentHouseworkImportCandidate(title: "風呂掃除", point: 10, isAlreadyRegistered: false)
        let expected = FrequentHouseworkImportSelection.ToggleResult.changed(.init(selectedTitles: []))

        // Act

        let actual = selection.toggling(candidate, remainingCount: 1)

        // Assert

        #expect(actual == expected)
    }

    @Test("登録済みの候補は、チェックを外せない")
    func togglingAlreadyRegisteredIsUnavailable() {
        // Arrange

        let selection = FrequentHouseworkImportSelection()
        let candidate = FrequentHouseworkImportCandidate(title: "洗濯", point: 20, isAlreadyRegistered: true)

        // Act

        let actual = selection.toggling(candidate, remainingCount: nil)

        // Assert

        #expect(actual == .unavailable)
    }

}

extension FrequentHouseworkImportSelectionTest.ImportTargetsCase {

    @Test("取り込むのは、チェックしていてまだ登録していない候補だけにする")
    func importTargetsExcludesAlreadyRegistered() {
        // Arrange

        let selection = FrequentHouseworkImportSelection(selectedTitles: ["風呂掃除", "洗濯"])
        let expected = [FrequentHouseworkImportCandidate(title: "風呂掃除", point: 10, isAlreadyRegistered: false)]

        // Act

        let actual = selection.importTargets(from: FrequentHouseworkImportSelectionTest.candidates)

        // Assert

        #expect(actual == expected)
    }

}
