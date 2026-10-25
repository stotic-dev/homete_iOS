//
//  InquiryMessageBodyTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct InquiryMessageBodyTest {

    @Test(
        "空、または空白・改行だけの本文は送れない",
        arguments: ["", " ", "　", "\n\n", " \t\n"]
    )
    func init_empty(text: String) {
        // Act
        let actual = InquiryMessageBody(text)

        // Assert
        #expect(actual == .empty)
    }

    @Test("上限ちょうどの文字数の本文は送れる")
    func init_maxLength() {
        // Arrange
        let text = String(repeating: "あ", count: 2000)

        // Act
        let actual = InquiryMessageBody(text)

        // Assert
        #expect(actual == .valid)
    }

    @Test("上限を超える文字数の本文は送れない")
    func init_tooLong() {
        // Arrange
        let text = String(repeating: "あ", count: 2001)

        // Act
        let actual = InquiryMessageBody(text)

        // Assert
        #expect(actual == .tooLong)
    }

    @Test("絵文字はサーバーと同じく1文字として数える")
    func init_emojiCountsAsOneCharacter() {
        // Arrange
        // 👨‍👩‍👧はUTF-16では8単位だが、書記素クラスタでは1文字
        let text = String(repeating: "👨‍👩‍👧", count: 2000)

        // Act
        let actual = InquiryMessageBody(text)

        // Assert
        #expect(actual == .valid)
    }

    @Test("結合文字を重ねてUTF-16の上限を超える本文は送れない")
    func init_tooLongInUTF16() {
        // Arrange
        // 1文字に結合文字を32,000個重ねる
        let text = "a" + String(repeating: "\u{0301}", count: 32000)

        // Act
        let actual = InquiryMessageBody(text)

        // Assert
        #expect(actual == .tooLong)
    }

}
