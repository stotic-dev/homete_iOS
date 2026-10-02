//
//  AppVersionTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct AppVersionTest {

    @Test(
        "各桁を数値として比べ、桁数が違う場合は足りない桁を0とみなす",
        arguments: [
            ("1.9.0", "1.10.0"),
            ("1.0.0", "1.0.1"),
            ("1.99.99", "2.0.0"),
            ("1.4", "1.4.1"),
            ("1.4.0", "1.5"),
        ]
    )
    func olderVersionIsLess(older: String, newer: String) throws {
        // Arrange

        let olderVersion = try #require(AppVersion(older))
        let newerVersion = try #require(AppVersion(newer))

        // Act

        let isLess = olderVersion < newerVersion

        // Assert

        #expect(isLess)
    }

    @Test(
        "桁数が違っても、足りない桁を0とみなして等しければ同じバージョンになる",
        arguments: [
            ("1.4", "1.4.0"),
            ("1.4.0", "1.4.0.0"),
            (" 1.4.0 ", "1.4.0"),
        ]
    )
    func sameVersionIsEqual(lhs: String, rhs: String) throws {
        // Arrange

        let lhsVersion = try #require(AppVersion(lhs))
        let rhsVersion = try #require(AppVersion(rhs))

        // Act

        let isEqual = lhsVersion == rhsVersion

        // Assert

        #expect(isEqual)
    }

    @Test(
        "ドット区切りの数字でない文字列はバージョンとして扱わない",
        arguments: ["", " ", "1..0", "1.0.", ".1", "1.0.0-beta", "v1.0.0", "+1.0", "１.0", "abc"]
    )
    func invalidStringIsNil(string: String) {
        // Act

        let version = AppVersion(string)

        // Assert

        #expect(version == nil)
    }

}
