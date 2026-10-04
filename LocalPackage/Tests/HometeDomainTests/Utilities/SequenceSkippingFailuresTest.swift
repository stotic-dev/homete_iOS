//
//  SequenceSkippingFailuresTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct SequenceSkippingFailuresTest {

    private struct ParseError: Error {}

    @Test("変換に失敗した要素だけを外し、残りの要素を変換して返す")
    func skipsFailedElements() {
        // Arrange

        let input = ["1", "x", "3"]

        // Act

        let actual = input.compactMapSkippingFailures(
            transform: { element in
                guard let value = Int(element) else { throw ParseError() }
                return value
            },
            onFailure: { _, _ in }
        )

        // Assert

        #expect(actual == [1, 3])
    }

    @Test("変換に失敗した要素がonFailureに渡される")
    func notifiesFailedElements() {
        // Arrange

        let input = ["1", "x", "3", "y"]
        var failedElements: [String] = []

        // Act

        _ = input.compactMapSkippingFailures(
            transform: { element in
                guard let value = Int(element) else { throw ParseError() }
                return value
            },
            onFailure: { element, _ in failedElements.append(element) }
        )

        // Assert

        #expect(failedElements == ["x", "y"])
    }

}
