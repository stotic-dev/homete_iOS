//
//  NotificationRouteTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct NotificationRouteTest {

    @Test("ありがとうの通知は、ありがとうが届いた家事の詳細画面を開く")
    func initUserInfo_thanksNotification_returnsHouseworkDetail() {
        // Arrange

        let userInfo: [AnyHashable: Any] = ["type": "houseworkThanks", "houseworkId": "houseworkId"]

        // Act

        let actual = NotificationRoute(userInfo: userInfo)

        // Assert

        #expect(actual == .houseworkDetail(houseworkId: "houseworkId"))
    }

    @Test(
        "開く画面が決まっていない通知では、画面を開かない",
        arguments: [
            ["type": "houseworkCompleted", "houseworkDate": "1790262000"],
            [:],
        ]
    )
    func initUserInfo_otherNotification_returnsNil(userInfo: [String: String]) {
        // Act

        let actual = NotificationRoute(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
