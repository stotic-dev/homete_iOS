//
//  HouseworkTutorialSampleTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkTutorialSampleTest {

    @Test("パートナーが読み込めている場合は、自分とパートナーをメンバーにする")
    func members_hasPartner_returnsOwnAndPartner() {
        // Act
        let result = HouseworkTutorialSample.members(
            ownId: "ownUserId",
            ownUserName: "たろう",
            others: [.init(id: "partnerId", userName: "はなこ")]
        )

        // Assert
        let expected = CohabitantMemberList(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "partnerId", userName: "はなこ"),
            ],
            ownId: "ownUserId"
        )
        #expect(result == expected)
    }

    @Test("パートナーがまだ読み込めていない場合は、仮のパートナーをメンバーにする")
    func members_noPartner_returnsPlaceholderPartner() {
        // Act
        let result = HouseworkTutorialSample.members(ownId: "ownUserId", ownUserName: "たろう", others: [])

        // Assert
        let expected = CohabitantMemberList(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "tutorial_partner", userName: "パートナー"),
            ],
            ownId: "ownUserId"
        )
        #expect(result == expected)
    }

    @Test("サンプルの家事のうち、パートナーが完了した家事だけがありがとうを伝えられる状態になる")
    func items_thanksStatus_onlyPartnerItemIsNotSent() {
        // Arrange
        let members = CohabitantMemberList(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "partnerId", userName: "はなこ"),
            ],
            ownId: "ownUserId"
        )

        // Act
        let items = HouseworkTutorialSample.items(today: .distantPast, members: members)

        // Assert
        let statuses = items.map {
            HouseworkThanksStatus.make(item: .init(originalItem: $0, isRegistered: true), ownUserId: "ownUserId")
        }
        #expect(statuses == [.notSent, nil, nil, nil, nil])
    }

}
