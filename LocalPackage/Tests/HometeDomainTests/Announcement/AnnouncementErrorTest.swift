//
//  AnnouncementErrorTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct AnnouncementErrorTest {

    @Test(
        "Functionsが返すお知らせ固有のコードを、対応するエラーに変換する",
        arguments: [
            ("invalid-argument", AnnouncementError.invalidArgument),
            ("announcement-not-found", AnnouncementError.notFound),
        ]
    )
    func init_knownServerCode(serverCode: String, expected: AnnouncementError) {
        // Act
        let actual = AnnouncementError(serverCode: serverCode)

        // Assert
        #expect(actual == expected)
    }

    @Test(
        "お知らせ固有でないコードは変換しない",
        arguments: ["failed-precondition", "unknown-code"]
    )
    func init_unknownServerCode(serverCode: String) {
        // Act
        let actual = AnnouncementError(serverCode: serverCode)

        // Assert
        #expect(actual == nil)
    }

}
