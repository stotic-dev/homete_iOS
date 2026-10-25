//
//  PendingRouteTest.swift
//  LocalPackage
//

@testable import HometeDomain
import Testing

struct PendingRouteTest {

    @Test("ありがとうの通知は、ありがとうが届いた家事の詳細画面を開く")
    func initUserInfo_thanksNotification_returnsHouseworkDetail() {
        // Arrange

        let userInfo: [AnyHashable: Any] = ["type": "houseworkThanks", "houseworkId": "houseworkId"]

        // Act

        let actual = PendingRoute(userInfo: userInfo)

        // Assert

        #expect(actual == .houseworkDetail(houseworkId: "houseworkId"))
    }

    @Test("問い合わせの返信の通知は、返信が届いた問い合わせの詳細画面を開く")
    func initUserInfo_inquiryReplyNotification_returnsInquiryDetail() {
        // Arrange

        let userInfo: [AnyHashable: Any] = ["type": "inquiryReply", "inquiryId": "inquiryId"]

        // Act

        let actual = PendingRoute(userInfo: userInfo)

        // Assert

        #expect(actual == .inquiryDetail(inquiryId: "inquiryId"))
    }

    @Test(
        "開く画面が決まっていない通知では、画面を開かない",
        arguments: [
            ["type": "houseworkCompleted", "houseworkDate": "1790262000"],
            ["type": "inquiryReply", "inquiryId": ""],
            ["type": "inquiryReply"],
            [:],
        ]
    )
    func initUserInfo_otherNotification_returnsNil(userInfo: [String: String]) {
        // Act

        let actual = PendingRoute(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
