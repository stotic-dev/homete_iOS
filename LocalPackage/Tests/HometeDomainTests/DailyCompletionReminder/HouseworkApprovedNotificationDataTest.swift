//
//  HouseworkApprovedNotificationDataTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct HouseworkApprovedNotificationDataTest {

    @Test("通知のdataには種類と家事の日付（UNIX秒）を文字列で載せる")
    func payload_returnsTypeAndHouseworkDate() {
        // Arrange

        let sut = HouseworkApprovedNotificationData(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))
        let expected = ["type": "houseworkApproved", "houseworkDate": "1790262000"]

        // Act

        let actual = sut.payload

        // Assert

        #expect(actual == expected)
    }

    @Test("家事の承認通知のuserInfoから家事の日付を復元できる")
    func initUserInfo_approvedNotification_returnsData() {
        // Arrange

        let userInfo: [AnyHashable: Any] = [
            "type": "houseworkApproved",
            "houseworkDate": "1790262000",
            "aps": ["mutable-content": 1],
        ]
        let expected = HouseworkApprovedNotificationData(houseworkDate: .previewDate(year: 2026, month: 9, day: 25))

        // Act

        let actual = HouseworkApprovedNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "家事の承認通知でない、または日付が読み取れないuserInfoからは復元しない",
        arguments: [
            ["type": "other", "houseworkDate": "1790262000"],
            ["houseworkDate": "1790262000"],
            ["type": "houseworkApproved"],
            ["type": "houseworkApproved", "houseworkDate": "invalid"],
        ]
    )
    func initUserInfo_invalidUserInfo_returnsNil(userInfo: [String: String]) {
        // Act

        let actual = HouseworkApprovedNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
