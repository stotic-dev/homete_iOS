//
//  FrequentHouseworkLimitPolicyTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

enum FrequentHouseworkLimitPolicyTest {

    struct CanAddCase {}
    struct RemainingCountCase {}
    struct UnusableItemIdsCase {}

}

extension FrequentHouseworkLimitPolicyTest.CanAddCase {

    @Test(
        "無料プランは、追加後の件数が10件以内なら追加できる",
        arguments: [
            (1, 9, true),
            (1, 10, false),
            (3, 7, true),
            (3, 8, false),
        ]
    )
    func freeCanAddWithinLimit(count: Int, currentCount: Int, expected: Bool) {
        // Arrange

        let policy = FrequentHouseworkLimitPolicy(isPremium: false)

        // Act

        let actual = policy.canAdd(count, currentCount: currentCount)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランは、件数に関係なく追加できる")
    func premiumCanAlwaysAdd() {
        // Arrange

        let policy = FrequentHouseworkLimitPolicy(isPremium: true)

        // Act

        let actual = policy.canAdd(5, currentCount: 100)

        // Assert

        #expect(actual == true)
    }

}

extension FrequentHouseworkLimitPolicyTest.RemainingCountCase {

    @Test(
        "無料プランは、上限までの残り件数を返す（超えている場合は0）",
        arguments: [
            (0, 10),
            (7, 3),
            (10, 0),
            (12, 0),
        ]
    )
    func freeRemainingCount(currentCount: Int, expected: Int) {
        // Arrange

        let policy = FrequentHouseworkLimitPolicy(isPremium: false)

        // Act

        let actual = policy.remainingCount(currentCount: currentCount)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランは、残り件数を持たない")
    func premiumHasNoRemainingCount() {
        // Arrange

        let policy = FrequentHouseworkLimitPolicy(isPremium: true)

        // Act

        let actual = policy.remainingCount(currentCount: 100)

        // Assert

        #expect(actual == nil)
    }

}

extension FrequentHouseworkLimitPolicyTest.UnusableItemIdsCase {

    @Test("無料プランで上限を超えている場合は、表示順で11件目以降が使えない")
    func freeOverLimitItemsAreUnusable() {
        // Arrange

        // 「その他」の12件（並び順0〜11）と、表示順が先頭になる掃除の1件
        let uncategorizedItems = (0 ..< 12).map {
            FrequentHouseworkItem.makeForTest(id: "u\($0)", sortOrder: $0)
        }
        let cleaning = FrequentHouseworkItem.makeForTest(id: "cleaning", categoryId: "preset.cleaning")
        let context = FrequentHouseworkContext(items: uncategorizedItems + [cleaning], customCategories: [])
        let policy = FrequentHouseworkLimitPolicy(isPremium: false)
        let expected: Set<String> = ["u9", "u10", "u11"]

        // Act

        let actual = policy.unusableItemIds(in: context)

        // Assert

        #expect(actual == expected)
    }

    @Test("プレミアムプランは、件数に関係なくすべて使える")
    func premiumHasNoUnusableItems() {
        // Arrange

        let items = (0 ..< 12).map { FrequentHouseworkItem.makeForTest(id: "\($0)", sortOrder: $0) }
        let context = FrequentHouseworkContext(items: items, customCategories: [])
        let policy = FrequentHouseworkLimitPolicy(isPremium: true)

        // Act

        let actual = policy.unusableItemIds(in: context)

        // Assert

        #expect(actual == [])
    }

}
