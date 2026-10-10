//
//  HouseworkThanksNotificationDataTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct HouseworkThanksNotificationDataTest {

    @Test("通知のdataには種類と家事のIDを載せる")
    func payload_returnsTypeAndHouseworkId() {
        // Arrange

        let sut = HouseworkThanksNotificationData(houseworkId: "houseworkId")
        let expected = ["type": "houseworkThanks", "houseworkId": "houseworkId"]

        // Act

        let actual = sut.payload

        // Assert

        #expect(actual == expected)
    }

    @Test("ありがとうの通知のuserInfoから家事のIDを復元できる")
    func initUserInfo_thanksNotification_returnsData() {
        // Arrange

        let userInfo: [AnyHashable: Any] = [
            "type": "houseworkThanks",
            "houseworkId": "houseworkId",
            "aps": ["mutable-content": 1],
        ]
        let expected = HouseworkThanksNotificationData(houseworkId: "houseworkId")

        // Act

        let actual = HouseworkThanksNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == expected)
    }

    @Test(
        "ありがとうの通知でない、または家事のIDが読み取れないuserInfoからは復元しない",
        arguments: [
            ["type": "houseworkCompleted", "houseworkId": "houseworkId"],
            ["houseworkId": "houseworkId"],
            ["type": "houseworkThanks"],
            ["type": "houseworkThanks", "houseworkId": ""],
        ]
    )
    func initUserInfo_invalidUserInfo_returnsNil(userInfo: [String: String]) {
        // Act

        let actual = HouseworkThanksNotificationData(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
