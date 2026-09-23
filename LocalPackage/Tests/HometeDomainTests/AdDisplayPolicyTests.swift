//
//  AdDisplayPolicyTests.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/23.
//

@testable import HometeDomain
import Testing

struct AdDisplayPolicyTests {

    @Test(
        "広告表示が有効かつプレミアム未加入の場合のみ広告を表示する",
        arguments: [
            (true, false, true),
            (true, true, false),
            (false, false, false),
            (false, true, false),
        ]
    )
    func shouldShowAds(isEnabled: Bool, isPremium: Bool, expected: Bool) {
        // Act
        let actual = AdDisplayPolicy.shouldShowAds(isPremium: isPremium, isEnabled: isEnabled)

        // Assert
        #expect(actual == expected)
    }

}
