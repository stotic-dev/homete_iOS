//
//  EncouragementToneValidatorTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct EncouragementToneValidatorTest {

    @Test("ガイドラインに沿ったコメントは、そのまま出せる")
    func validated_acceptableText_returnsText() {
        // Act
        let actual = EncouragementToneValidator.validated("今日も洗い物、おつかれさまです")

        // Assert
        #expect(actual == "今日も洗い物、おつかれさまです")
    }

    @Test("前後の空白・改行とかぎかっこを取り除く")
    func validated_enclosedText_returnsNormalizedText() {
        // Act
        let actual = EncouragementToneValidator.validated("  「今日もおつかれさまです。\nゆっくり休んでください」\n")

        // Assert
        #expect(actual == "今日もおつかれさまです。ゆっくり休んでください")
    }

    @Test(
        "責める・比べる・要求する・未完了を指摘する表現を含むコメントは出さない",
        arguments: [
            "今日は洗い物しかしていないですね",
            "はなこさんより多くこなしました",
            "はなこさんのほうがたくさんやっています",
            "今月は一番がんばりました",
            "家事の60%を担当しています",
            "もっと家事をしましょう",
            "洗濯は未完了です",
            "家事の偏りが気になります",
        ]
    )
    func validated_forbiddenPhrase_returnsNil(text: String) {
        // Act
        let actual = EncouragementToneValidator.validated(text)

        // Assert
        #expect(actual == nil)
    }

    @Test("空のコメントは出さない")
    func validated_emptyText_returnsNil() {
        // Act
        let actual = EncouragementToneValidator.validated(" \n「」")

        // Assert
        #expect(actual == nil)
    }

    @Test("上限の文字数を超えるコメントは出さない")
    func validated_tooLongText_returnsNil() {
        // Arrange
        let text = String(repeating: "あ", count: 81)

        // Act
        let actual = EncouragementToneValidator.validated(text)

        // Assert
        #expect(actual == nil)
    }

    @Test("上限の文字数ちょうどのコメントは出せる")
    func validated_maxLengthText_returnsText() {
        // Arrange
        let text = String(repeating: "あ", count: 80)

        // Act
        let actual = EncouragementToneValidator.validated(text)

        // Assert
        #expect(actual == text)
    }

    @Test("固定文言はどれも禁止表現を含まず、そのまま出せる", arguments: EncouragementFixedComment.allTexts)
    func validated_fixedText_returnsText(text: String) {
        // Act
        let actual = EncouragementToneValidator.validated(text)

        // Assert
        #expect(actual == text)
    }

}
