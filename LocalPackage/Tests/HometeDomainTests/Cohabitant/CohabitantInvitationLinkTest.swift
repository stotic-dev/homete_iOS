//
//  CohabitantInvitationLinkTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct CohabitantInvitationLinkTest {

    @Test("招待トークンからLINE向けのクエリ付きで招待リンクのURLを生成する")
    func url() {
        // Arrange
        let inputToken = "test-token"

        // Act
        let actual = CohabitantInvitationLink.url(token: inputToken)

        // Assert
        #expect(actual == URL(string: "https://homete-ios-dev-e3ef7.web.app/invite/test-token?openExternalBrowser=1"))
    }

    @Test("トークンが空文字の場合はURLを生成しない")
    func url_emptyToken() {
        // Arrange
        let inputToken = ""

        // Act
        let actual = CohabitantInvitationLink.url(token: inputToken)

        // Assert
        #expect(actual == nil)
    }

    @Test(
        "招待リンクのURLから招待トークンを取り出す",
        arguments: [
            // クエリなし（Smart App Banner・クリップボード経由）
            "https://homete-ios-dev-e3ef7.web.app/invite/test-token",
            // 共有したURLそのもの（LINE向けのクエリ付き）
            "https://homete-ios-dev-e3ef7.web.app/invite/test-token?openExternalBrowser=1",
            // 着地ページの「アプリで開く」（カスタムURLスキーム）
            "homeau-dev://invite/test-token",
        ]
    )
    func token(urlString: String) throws {
        // Arrange
        let inputURL = try #require(URL(string: urlString))

        // Act
        let actual = CohabitantInvitationLink.token(from: inputURL)

        // Assert
        #expect(actual == "test-token")
    }

    @Test(
        "招待リンクではないURLからは招待トークンを取り出さない",
        arguments: [
            // ホストが異なる
            "https://example.com/invite/test-token",
            // スキームが異なる
            "http://homete-ios-dev-e3ef7.web.app/invite/test-token",
            // パスが異なる
            "https://homete-ios-dev-e3ef7.web.app/privacy/test-token",
            // トークンがない
            "https://homete-ios-dev-e3ef7.web.app/invite",
            // パスの階層が深い
            "https://homete-ios-dev-e3ef7.web.app/invite/test-token/extra",
            // 本番のカスタムURLスキーム（開発ビルドでは受け付けない）
            "homeau://invite/test-token",
            // RevenueCatなど、招待以外のカスタムURLスキーム
            "hometedev://invite/test-token",
            // カスタムURLスキームでホストが異なる
            "homeau-dev://privacy/test-token",
            // カスタムURLスキームでトークンがない
            "homeau-dev://invite",
            // カスタムURLスキームでパスの階層が深い
            "homeau-dev://invite/test-token/extra",
        ]
    )
    func token_notInvitationLink(urlString: String) throws {
        // Arrange
        let inputURL = try #require(URL(string: urlString))

        // Act
        let actual = CohabitantInvitationLink.token(from: inputURL)

        // Assert
        #expect(actual == nil)
    }

    @Test(
        "URLから招待トークンと起動経路を取り出す",
        arguments: [
            (
                "https://homete-ios-dev-e3ef7.web.app/invite/test-token?openExternalBrowser=1",
                CohabitantInvitationLink.Parsed(token: "test-token", source: .universalLink)
            ),
            (
                "homeau-dev://invite/test-token",
                CohabitantInvitationLink.Parsed(token: "test-token", source: .customScheme)
            ),
        ]
    )
    func parse(urlString: String, expected: CohabitantInvitationLink.Parsed) throws {
        // Arrange
        let inputURL = try #require(URL(string: urlString))

        // Act
        let actual = CohabitantInvitationLink.parse(inputURL)

        // Assert
        #expect(actual == expected)
    }

}
