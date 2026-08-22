//
//  AccountTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/22.
//

import Foundation
@testable import HometeDomain
import Testing

struct AccountTest {

    /// `Account`は`init(from:)`を明示的に実装している。
    /// 合成される実装は`isPremium`が非Optionalなためキーが無いと`keyNotFound`で失敗し、
    /// `isPremium`導入前に作られた既存ドキュメントを読めなくなる（プロパティの初期値を書いても同じ）。
    /// このテストが落ちる場合、`init(from:)`を消してはいけない。
    @Test("isPremiumを持たないドキュメントは無料プランとしてデコードされる")
    func decodeWithoutIsPremium() throws {
        // Arrange

        let json = Data(#"{"id":"id","userName":"userName","cohabitantId":"cohabitantId"}"#.utf8)
        let expected = Account(
            id: "id",
            userName: "userName",
            fcmToken: nil,
            cohabitantId: "cohabitantId",
            isPremium: false
        )

        // Act

        let actual = try JSONDecoder().decode(Account.self, from: json)

        // Assert

        #expect(actual == expected)
    }

    @Test("isPremiumを持つドキュメントはその値でデコードされる")
    func decodeWithIsPremium() throws {
        // Arrange

        let json = Data(#"""
        {"id":"id","userName":"userName","fcmToken":"fcmToken","cohabitantId":"cohabitantId","isPremium":true}
        """#.utf8)
        let expected = Account(
            id: "id",
            userName: "userName",
            fcmToken: "fcmToken",
            cohabitantId: "cohabitantId",
            isPremium: true
        )

        // Act

        let actual = try JSONDecoder().decode(Account.self, from: json)

        // Assert

        #expect(actual == expected)
    }

}
