//
//  InquiryErrorTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct InquiryErrorTest {

    @Test(
        "Functionsが返す問い合わせ固有のコードを、対応するエラーに変換する",
        arguments: [
            ("invalid-argument", InquiryError.invalidArgument),
            ("inquiry-not-found", InquiryError.notFound),
            ("message-not-found", InquiryError.notFound),
            ("rate-limited", InquiryError.rateLimited),
        ]
    )
    func init_knownServerCode(serverCode: String, expected: InquiryError) {
        // Act
        let actual = InquiryError(serverCode: serverCode)

        // Assert
        #expect(actual == expected)
    }

    @Test(
        "問い合わせ固有でないコードは変換しない",
        arguments: ["account-deleted", "unknown-code"]
    )
    func init_unknownServerCode(serverCode: String) {
        // Act
        let actual = InquiryError(serverCode: serverCode)

        // Assert
        #expect(actual == nil)
    }

    @Test(
        "エラーから画面に出す失敗の理由を組み立てる",
        arguments: [
            (InquiryError.rateLimited as any Error, InquiryFailure.rateLimited),
            (InquiryError.invalidArgument as any Error, InquiryFailure.invalidInput),
            (InquiryError.notFound as any Error, InquiryFailure.notFound),
            (DomainError.noNetwork as any Error, InquiryFailure.domain(.noNetwork)),
            (CohabitantInvitationError.expired as any Error, InquiryFailure.domain(.other)),
        ]
    )
    func failure_init(error: any Error, expected: InquiryFailure) {
        // Act
        let actual = InquiryFailure(error)

        // Assert
        #expect(actual == expected)
    }

}
