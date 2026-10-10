//
//  PushNotificationContentTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

struct PushNotificationContentTest {

    /// `swift test`のランナーはローカライズを持たず、言語を指定しないと英語の訳になるため、日本語を指定して確かめる
    private let japanese = Locale(identifier: "ja")

    @Test("自分で終えた家事の完了通知は、終えた人と家事の名前を載せる")
    func completedMessage_returnsTitleAndBody() {
        // Arrange

        let sut = PushNotificationContent.completedMessage(
            executorName: "たろう",
            houseworkTitle: "洗濯",
            comment: "",
            data: nil
        )

        // Act

        let actual = (title: sut.title(locale: japanese), body: sut.body(locale: japanese))

        // Assert

        #expect(actual == (title: "たろうさんが家事を終えました", body: "「洗濯」が完了しました"))
    }

    @Test("コメントを添えた場合は、本文の次の行に載せる")
    func completedMessage_withComment_appendsCommentToBody() {
        // Arrange

        let sut = PushNotificationContent.completedMessage(
            executorName: "たろう",
            houseworkTitle: "洗濯",
            comment: "干しておきました",
            data: nil
        )

        // Act

        let actual = sut.body(locale: japanese)

        // Assert

        #expect(actual == "「洗濯」が完了しました\n干しておきました")
    }

    @Test("代わりに完了にした通知は、記録した人と担当者の名前を載せる")
    func proxyCompletedMessage_returnsTitleAndBody() {
        // Arrange

        let sut = PushNotificationContent.proxyCompletedMessage(
            reporterName: "たろう",
            executorNames: ["たろう", "はなこ"],
            houseworkTitle: "洗濯",
            comment: "",
            data: nil
        )

        // Act

        let actual = (title: sut.title(locale: japanese), body: sut.body(locale: japanese))

        // Assert

        #expect(actual == (title: "たろうさんが家事の完了を記録しました", body: "「洗濯」（担当：たろうさん・はなこさん）"))
    }

    @Test("まとめて完了にした通知は、件数を載せる")
    func completedBulkMessage_returnsTitleAndBody() {
        // Arrange

        let sut = PushNotificationContent.completedBulkMessage(
            executorName: "たろう",
            count: 3,
            data: .init(houseworkDate: Date(timeIntervalSince1970: 0))
        )

        // Act

        let actual = (title: sut.title(locale: japanese), body: sut.body(locale: japanese))

        // Assert

        #expect(actual == (title: "たろうさんが家事を終えました", body: "3件の家事が完了しました"))
    }

    @Test("ありがとうの通知は、送った人と家事の名前をタイトルに、コメントを本文に載せる")
    func thanksMessage_returnsTitleAndBody() {
        // Arrange

        let sut = PushNotificationContent.thanksMessage(
            senderName: "はなこ",
            houseworkTitle: "洗濯",
            houseworkId: "houseworkId",
            comment: "ありがとう！"
        )

        // Act

        let actual = (title: sut.title(locale: japanese), body: sut.body(locale: japanese))

        // Assert

        #expect(actual == (title: "はなこさんから「洗濯」にありがとうが届きました", body: "ありがとう！"))
    }

    @Test(
        "通知のdataから、送ったときと同じ内容を復元できる",
        arguments: [
            PushNotificationContent.completedMessage(
                executorName: "たろう",
                houseworkTitle: "洗濯",
                comment: "干しておきました",
                data: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
            ),
            .proxyCompletedMessage(
                reporterName: "たろう",
                executorNames: ["たろう", "はなこ"],
                houseworkTitle: "洗濯",
                comment: "",
                data: nil
            ),
            .completedBulkMessage(
                executorName: "たろう",
                count: 2,
                data: .init(houseworkDate: Date(timeIntervalSince1970: 1_790_262_000))
            ),
            .thanksMessage(senderName: "はなこ", houseworkTitle: "洗濯", houseworkId: "houseworkId", comment: "ありがとう！"),
        ]
    )
    func initUserInfo_payload_restoresContent(content: PushNotificationContent) {
        // Act

        let actual = PushNotificationContent(userInfo: content.payload)

        // Assert

        #expect(actual == content)
    }

    @Test("通知の種類が載っていない場合（古いアプリから届いた通知など）は復元しない")
    func initUserInfo_withoutMessage_returnsNil() {
        // Arrange

        let userInfo: [AnyHashable: Any] = ["type": "houseworkCompleted", "houseworkDate": "1790262000"]

        // Act

        let actual = PushNotificationContent(userInfo: userInfo)

        // Assert

        #expect(actual == nil)
    }

}
