//
//  HouseworkSuggestionEntityTest.swift
//  LocalPackage
//

@testable import HometeAppIntents
import Testing

struct HouseworkSuggestionEntityTest {

    @Test(
        "IDから、サーバーに問い合わせずに同じ候補に戻せる",
        arguments: [
            VoiceHouseworkTarget.today(title: "洗濯物干し"),
            .frequent(id: "abc123", title: "買い物: スーパー"),
            .title("窓ふき"),
        ]
    )
    func roundTrip(target: VoiceHouseworkTarget) {
        // Arrange

        let id = HouseworkSuggestionEntity(target: target).id

        // Act

        let actual = HouseworkSuggestionEntity(id: id)?.target

        // Assert

        #expect(actual == target)
    }

    @Test("知らない形のIDは候補に戻さない", arguments: ["", "unknown:洗濯", "frequent:abc123"])
    func unknownId(id: String) {
        // Act

        let actual = HouseworkSuggestionEntity(id: id)

        // Assert

        #expect(actual == nil)
    }

}
