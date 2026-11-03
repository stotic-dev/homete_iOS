//
//  HouseworkImagePolicyTest.swift
//  LocalPackage
//

@testable import HometeModel
import Testing

struct HouseworkImagePolicyTest {

    @Test(
        "あと何枚添えられるかは、プレミアムプランなら10枚から今の枚数を引いた数、無料プランなら0",
        arguments: [
            (true, 0, 10),
            (true, 9, 1),
            (true, 10, 0),
            (true, 11, 0),
            (false, 0, 0),
        ]
    )
    func addableCount(isPremium: Bool, currentCount: Int, expected: Int) {
        // Arrange
        let policy = HouseworkImagePolicy(isPremium: isPremium)

        // Act
        let actual = policy.addableCount(currentCount: currentCount)

        // Assert
        #expect(actual == expected)
    }

    @Test("プレミアムプランなら、合わせて10枚までは添えられる")
    func validateAdding_premiumWithinLimit_doesNotThrow() throws {
        // Arrange
        let policy = HouseworkImagePolicy.premium

        // Act & Assert
        try policy.validateAdding(count: 3, currentCount: 7)
    }

    @Test(
        "無料プラン、または合わせて10枚を超える場合は添えられない",
        arguments: [
            (false, 1, 0, HouseworkImageError.premiumRequired),
            (true, 4, 7, .limitExceeded),
        ]
    )
    func validateAdding_notAllowed_throws(
        isPremium: Bool,
        count: Int,
        currentCount: Int,
        expected: HouseworkImageError
    ) {
        // Arrange
        let policy = HouseworkImagePolicy(isPremium: isPremium)

        // Act & Assert
        #expect(throws: expected) {
            try policy.validateAdding(count: count, currentCount: currentCount)
        }
    }

    @Test(
        "画像を消せるのは、プレミアムプランか、自分が追加した画像のとき",
        arguments: [
            (true, "userB", true),
            (false, "userA", true),
            (false, "userB", false),
        ]
    )
    func canDelete(isPremium: Bool, uploaderId: String, expected: Bool) {
        // Arrange
        let policy = HouseworkImagePolicy(isPremium: isPremium)
        let image = HouseworkImage(id: "image1", storagePath: "path", uploaderId: uploaderId)

        // Act
        let actual = policy.canDelete(image, userId: "userA")

        // Assert
        #expect(actual == expected)
    }

}
