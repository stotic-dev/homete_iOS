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

    @Test("ポイント降順でランク付けされ、自分のユーザーIDと一致するアイテムは自分自身のアイテムであるフラグが立つ")
    func makeRanking_assignsRanksInDescendingPointOrder() {

        // Arrange
        let summary = AllUserPointSummary(items: [
            UserPointSummary(userId: "alice", userName: "アリス", isMe: true, monthlyPoint: .init(value: 40), achievedCount: 2),
            UserPointSummary(userId: "bob", userName: "ボブ", isMe: false, monthlyPoint: .init(value: 120), achievedCount: 5),
            UserPointSummary(userId: "carol", userName: "キャロル", isMe: false, monthlyPoint: .init(value: 80), achievedCount: 3)
        ])

        // Act
        let result = summary.makeRanking()

        // Assert
        let expected: [ContributionRankItem] = [
            .init(rank: 1, userId: "bob", userName: "ボブ", isMe: false, monthlyPoint: .init(value: 120), achievedCount: 5),
            .init(rank: 2, userId: "carol", userName: "キャロル", isMe: false, monthlyPoint: .init(value: 80), achievedCount: 3),
            .init(rank: 3, userId: "alice", userName: "アリス", isMe: true, monthlyPoint: .init(value: 40), achievedCount: 2)
        ]
        #expect(result == expected)
    }

    @Test("アイテムが空の場合はランキングも空になる")
    func makeRanking_returnsEmptyRanking_whenNoItems() {

        // Arrange
        let summary = AllUserPointSummary()

        // Act
        let result = summary.makeRanking()

        // Assert
        #expect(result == [])
    }
}
