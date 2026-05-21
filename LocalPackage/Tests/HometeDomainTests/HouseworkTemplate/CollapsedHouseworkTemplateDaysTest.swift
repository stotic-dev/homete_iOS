//
//  CollapsedHouseworkTemplateDaysTest.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/21.
//

@testable import HometeDomain
import Testing

struct CollapsedHouseworkTemplateDaysTest {

    @Test("折りたたみ対象に含まれていない曜日はisCollapsedがfalseを返す")
    func isCollapsed_returnsFalseWhenDayIsNotCollapsed() {
        // Arrange
        let sut = CollapsedHouseworkTemplateDays(days: [.monday, .tuesday])

        // Act
        let result = sut.isCollapsed(.wednesday)

        // Assert
        #expect(result == false)
    }

    @Test("折りたたみ対象に含まれている曜日はisCollapsedがtrueを返す")
    func isCollapsed_returnsTrueWhenDayIsCollapsed() {
        // Arrange
        let sut = CollapsedHouseworkTemplateDays(days: [.monday, .tuesday])

        // Act
        let result = sut.isCollapsed(.monday)

        // Assert
        #expect(result == true)
    }

    @Test("展開中の曜日をtoggleすると折りたたみ状態になる")
    func toggle_addsDayWhenNotCollapsed() {
        // Arrange
        var sut = CollapsedHouseworkTemplateDays(days: [.monday])
        let expected = CollapsedHouseworkTemplateDays(days: [.monday, .tuesday])

        // Act
        sut.toggle(.tuesday)

        // Assert
        #expect(sut == expected)
    }

    @Test("折りたたみ中の曜日をtoggleすると展開状態になる")
    func toggle_removesDayWhenCollapsed() {
        // Arrange
        var sut = CollapsedHouseworkTemplateDays(days: [.monday, .tuesday])
        let expected = CollapsedHouseworkTemplateDays(days: [.tuesday])

        // Act
        sut.toggle(.monday)

        // Assert
        #expect(sut == expected)
    }

    @Test("rawValueとinit(rawValue:)で値が往復できる")
    func rawValueRoundTrip() {
        // Arrange
        let sut = CollapsedHouseworkTemplateDays(days: [.monday, .friday, .sunday])

        // Act
        let restored = CollapsedHouseworkTemplateDays(rawValue: sut.rawValue)

        // Assert
        #expect(restored == sut)
    }

    @Test("不正なrawValueからinitすると失敗する")
    func initRawValue_returnsNilWhenInvalid() {
        // Arrange
        let invalidRawValue = "invalid"

        // Act
        let result = CollapsedHouseworkTemplateDays(rawValue: invalidRawValue)

        // Assert
        #expect(result == nil)
    }

}
