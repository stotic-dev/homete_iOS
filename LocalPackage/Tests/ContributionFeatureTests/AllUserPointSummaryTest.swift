//
//  AllUserPointSummaryTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import Testing
import HometeDomain
@testable import ContributionFeature

// swiftlint:disable:next convenience_type
struct AllUserPointSummaryTest {
    struct MakeRankingCase {}
}

extension AllUserPointSummaryTest.MakeRankingCase {

    @Test("ポイント降順でランク付けされる")
    func makeRanking_assignsRanksInDescendingPointOrder() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "alice", monthlyPoint: .init(value: 40), achievedCount: 2),
            UserPointSummary(userId: "bob", monthlyPoint: .init(value: 120), achievedCount: 5),
            UserPointSummary(userId: "carol", monthlyPoint: .init(value: 80), achievedCount: 3)
        ])
        let members = CohabitantMemberList(value: [
            .init(id: "alice", userName: "アリス"),
            .init(id: "bob", userName: "ボブ"),
            .init(id: "carol", userName: "キャロル")
        ])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "alice")

        // Assert
        #expect(result[0].rank == 1)
        #expect(result[0].userId == "bob")
        #expect(result[1].rank == 2)
        #expect(result[1].userId == "carol")
        #expect(result[2].rank == 3)
        #expect(result[2].userId == "alice")
    }

    @Test("自分のユーザーIDと一致するアイテムのisMeがtrueになる")
    func makeRanking_setsMeFlag_forMyUserId() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "alice", monthlyPoint: .init(value: 100), achievedCount: 3),
            UserPointSummary(userId: "bob", monthlyPoint: .init(value: 80), achievedCount: 2)
        ])
        let members = CohabitantMemberList(value: [
            .init(id: "alice", userName: "アリス"),
            .init(id: "bob", userName: "ボブ")
        ])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "alice")

        // Assert
        #expect(result.first(where: { $0.userId == "alice" })?.isMe == true)
        #expect(result.first(where: { $0.userId == "bob" })?.isMe == false)
    }

    @Test("membersに存在するユーザーIDの場合は登録名が表示される")
    func makeRanking_usesUserName_fromMembers() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "alice", monthlyPoint: .init(value: 100), achievedCount: 3)
        ])
        let members = CohabitantMemberList(value: [
            .init(id: "alice", userName: "アリス")
        ])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "alice")

        // Assert
        #expect(result[0].userName == "アリス")
    }

    @Test("membersに存在しないユーザーIDの場合はIDがそのまま表示名になる")
    func makeRanking_fallsBackToUserId_whenMemberNotFound() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "unknown-user", monthlyPoint: .init(value: 100), achievedCount: 3)
        ])
        let members = CohabitantMemberList(value: [])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "other")

        // Assert
        #expect(result[0].userName == "unknown-user")
    }

    @Test("アイテムが空の場合はランキングも空になる")
    func makeRanking_returnsEmptyRanking_whenNoItems() {

        // Arrange
        let summary = AllUserPointSummary()
        let members = CohabitantMemberList(value: [])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "alice")

        // Assert
        #expect(result.isEmpty)
    }

    @Test("ランキングアイテムのmonthlyPointとachievedCountが正しく引き継がれる")
    func makeRanking_propagatesPointAndAchievedCount() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "alice", monthlyPoint: .init(value: 120), achievedCount: 5)
        ])
        let members = CohabitantMemberList(value: [
            .init(id: "alice", userName: "アリス")
        ])

        // Act
        let result = summary.makeRanking(members: members, myUserId: "alice")

        // Assert
        #expect(result[0].monthlyPoint == .init(value: 120))
        #expect(result[0].achievedCount == 5)
    }
}
