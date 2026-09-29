//
//  HouseworkThanksMessageTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
@testable import HouseworkFeature
import Testing

struct HouseworkThanksMessageTest {

    @Test("届いたありがとうを、送られた順に送った人の名前とメッセージで並べる")
    func make_multipleThanks_sortedBySentAt() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId",
            thanks: [
                "laterUserId": .init(comment: "助かりました", sentAt: Date(timeIntervalSince1970: 2000)),
                "earlierUserId": .init(comment: "いつもありがとう", sentAt: Date(timeIntervalSince1970: 1000)),
            ]
        )
        let memberList = CohabitantMemberList(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "earlierUserId", userName: "はなこ"),
                .init(id: "laterUserId", userName: "じろう"),
            ],
            ownId: "ownUserId"
        )

        // Act
        let result = HouseworkThanksMessage.make(item: item, memberList: memberList)

        // Assert
        let expected: [HouseworkThanksMessage] = [
            .init(senderName: "はなこ", comment: "いつもありがとう"),
            .init(senderName: "じろう", comment: "助かりました"),
        ]
        #expect(result == expected)
    }

    @Test("メッセージを書かずに伝えたありがとうは、コメントなしとして並べる")
    func make_thanksWithoutComment_returnsNilComment() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId",
            thanks: ["otherUserId": .init(comment: nil, sentAt: .distantPast)]
        )
        let memberList = CohabitantMemberList(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "otherUserId", userName: "はなこ"),
            ],
            ownId: "ownUserId"
        )

        // Act
        let result = HouseworkThanksMessage.make(item: item, memberList: memberList)

        // Assert
        #expect(result == [.init(senderName: "はなこ", comment: nil)])
    }

    @Test("グループを抜けたなどで名前が分からない人のありがとうは出さない")
    func make_unknownSender_excluded() {
        // Arrange
        let item = HouseworkBoardItem.makeForPreview(
            id: "1",
            state: .completed,
            executorId: "ownUserId",
            thanks: ["leftUserId": .init(comment: "ありがとう", sentAt: .distantPast)]
        )
        let memberList = CohabitantMemberList(
            value: [.init(id: "ownUserId", userName: "たろう")],
            ownId: "ownUserId"
        )

        // Act
        let result = HouseworkThanksMessage.make(item: item, memberList: memberList)

        // Assert
        #expect(result == [])
    }

}
