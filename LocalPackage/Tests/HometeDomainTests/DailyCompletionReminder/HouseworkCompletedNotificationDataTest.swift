//
//  HouseworkCompletedNotificationDataTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct HouseworkCompletedNotificationDataTest {

    @Test("通知のdataには種類と家事の日付（UNIX秒）を文字列で載せる")
    func payload_returnsTypeAndHouseworkDate() {
        // Arrange

        let sut = HouseworkCompletedNotificationData(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))
        let expected = ["type": "houseworkCompleted", "houseworkDate": "1790262000"]

        // Act

        let actual = sut.payload

        // Assert

        #expect(actual == expected)
    }

    @Test("家事の完了通知のuserInfoから家事の日付を復元できる")
    func initUserInfo_completedNotification_returnsData() {
        // Arrange

        let userInfo: [AnyHashable: Any] = [
            "type": "houseworkCompleted",
            "houseworkDate": "1790262000",
            "aps": ["mutable-content": 1],
        ]
        let expected = HouseworkCompletedNotificationData(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))

        // Act

        let actual = HouseworkCompletedNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "家事の完了通知でない、または日付が読み取れないuserInfoからは復元しない",
        arguments: [
            ["type": "other", "houseworkDate": "1790262000"],
            ["houseworkDate": "1790262000"],
            ["type": "houseworkCompleted"],
            ["type": "houseworkCompleted", "houseworkDate": "invalid"],
        ]
    )
    func initUserInfo_invalidUserInfo_returnsNil(userInfo: [String: String]) {
        // Act

        let actual = HouseworkCompletedNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
