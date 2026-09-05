//
//  CohabitantInvitationLinkTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct CohabitantInvitationLinkTest {

    @Test("招待トークンから招待リンクのURLを生成する")
    func url() {
        // Arrange
        let inputToken = "test-token"

        // Act
        let actual = CohabitantInvitationLink.url(token: inputToken)

        // Assert
        #expect(actual == URL(string: "https://homete-ios-dev-e3ef7.web.app/invite/test-token"))
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

    @Test("招待リンクのURLから招待トークンを取り出す")
    func token() throws {
        // Arrange
        let inputURL = try #require(URL(string: "https://homete-ios-dev-e3ef7.web.app/invite/test-token"))

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

}
