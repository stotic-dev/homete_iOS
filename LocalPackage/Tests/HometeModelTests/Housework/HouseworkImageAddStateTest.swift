//
//  HouseworkImageAddStateTest.swift
//  LocalPackage
//

@testable import HometeModel
import Testing

struct HouseworkImageAddStateTest {

    @Test(
        "追加ボタンの状態は、家事に添えられるか・プラン・添えてある枚数で決まる",
        arguments: [
            (false, HouseworkImagePolicy.premium, 0, HouseworkImageAddState.hidden),
            (false, .free, 0, .hidden),
            (true, .free, 0, .premiumRequired),
            (true, .free, 3, .premiumRequired),
            (true, .premium, 0, .available(remainingCount: 10)),
            (true, .premium, 9, .available(remainingCount: 1)),
            (true, .premium, 10, .limitReached),
        ]
    )
    func make(canAdd: Bool, policy: HouseworkImagePolicy, currentCount: Int, expected: HouseworkImageAddState) {
        // Act
        let actual = HouseworkImageAddState.make(canAdd: canAdd, policy: policy, currentCount: currentCount)

        // Assert
        #expect(actual == expected)
    }

}
