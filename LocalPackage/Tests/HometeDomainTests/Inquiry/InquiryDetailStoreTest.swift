//
//  InquiryDetailStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct InquiryDetailStoreTest {

    // MARK: - load

    @Test("取得したメッセージを古い順に並べ、さらに古いメッセージの位置を持つ")
    func load_success() async {
        // Arrange
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(fetch: { inquiryId, cursor in
                #expect(inquiryId == "inquiry")
                #expect(cursor == nil)
                return .init(
                    inquiry: .makeForTest(id: "inquiry"),
                    messages: [.makeForTest(id: "3"), .makeForTest(id: "2")],
                    nextCursor: "older"
                )
            })
        )

        // Act
        await sut.load()

        // Assert
        let expected = InquiryDetailState(
            inquiry: .makeForTest(id: "inquiry"),
            messages: [.makeForTest(id: "2"), .makeForTest(id: "3")],
            olderCursor: "older"
        )
        #expect(sut.state == expected)
    }

    @Test("運営の返信が未読なら、表示した最新のメッセージまで既読にして一覧へ伝える")
    func load_marksReadWhenUnread() async {
        // Arrange
        let markedMessageIds = TestLockedArray<String>()
        let updatedInquiries = TestBox<[Inquiry]>(value: [])
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(
                fetch: { _, _ in
                    .init(
                        inquiry: .makeForTest(id: "inquiry", hasUnreadReply: true),
                        messages: [.makeForTest(id: "2", sender: .admin), .makeForTest(id: "1")],
                        nextCursor: nil
                    )
                },
                markRead: { _, messageId in
                    await markedMessageIds.append(messageId)
                    return .makeForTest(id: "inquiry")
                }
            ),
            onUpdate: { updatedInquiries.value.append($0) }
        )

        // Act
        await sut.load()

        // Assert
        #expect(await markedMessageIds.values == ["2"])
        #expect(updatedInquiries.value == [.makeForTest(id: "inquiry")])
        let expected = InquiryDetailState(
            inquiry: .makeForTest(id: "inquiry"),
            messages: [.makeForTest(id: "1"), .makeForTest(id: "2", sender: .admin)]
        )
        #expect(sut.state == expected)
    }

    @Test("未読の返信が無ければ既読にしない")
    func load_doesNotMarkReadWithoutUnread() async {
        // Arrange
        let markReadCount = TestCounter()
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(
                fetch: { _, _ in
                    .init(inquiry: .makeForTest(id: "inquiry"), messages: [.makeForTest(id: "1")], nextCursor: nil)
                },
                markRead: { _, _ in
                    await markReadCount.increment()
                    return .makeForTest(id: "inquiry")
                }
            )
        )

        // Act
        await sut.load()

        // Assert
        #expect(await markReadCount.value == 0)
    }

    @Test("問い合わせが見つからなければ、見つからない失敗として入れる")
    func load_notFound() async {
        // Arrange
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(fetch: { _, _ in throw InquiryError.notFound })
        )

        // Act
        await sut.load()

        // Assert
        #expect(sut.state == InquiryDetailState(loadFailure: .notFound))
    }

    // MARK: - loadOlder

    @Test("さらに古いメッセージを取得すると、表示中のメッセージの前に足す")
    func loadOlder_prependsMessages() async {
        // Arrange
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(fetch: { _, cursor in
                if cursor == "older" {
                    return .init(
                        inquiry: .makeForTest(id: "inquiry"),
                        messages: [.makeForTest(id: "2"), .makeForTest(id: "1")],
                        nextCursor: nil
                    )
                }
                return .init(
                    inquiry: .makeForTest(id: "inquiry"),
                    messages: [.makeForTest(id: "4"), .makeForTest(id: "3")],
                    nextCursor: "older"
                )
            })
        )
        await sut.load()

        // Act
        await sut.loadOlder()

        // Assert
        let expected = InquiryDetailState(
            inquiry: .makeForTest(id: "inquiry"),
            messages: [.makeForTest(id: "1"), .makeForTest(id: "2"), .makeForTest(id: "3"), .makeForTest(id: "4")]
        )
        #expect(sut.state == expected)
    }

    // MARK: - submit

    @Test("メッセージを送ると、末尾に足して入力を空にし、一覧へ伝える")
    func submit_success() async {
        // Arrange
        let sentArguments = TestLockedArray<[String]>()
        let updatedInquiries = TestBox<[Inquiry]>(value: [])
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(
                fetch: { _, _ in
                    .init(inquiry: .makeForTest(id: "inquiry"), messages: [.makeForTest(id: "1")], nextCursor: nil)
                },
                sendMessage: { inquiryId, requestId, body in
                    await sentArguments.append([inquiryId, requestId, body])
                    return .init(
                        inquiry: .makeForTest(id: "inquiry", updatedAt: Date(timeIntervalSince1970: 100)),
                        message: .makeForTest(id: "2")
                    )
                }
            ),
            makeRequestId: { "request-1" },
            onUpdate: { updatedInquiries.value.append($0) }
        )
        await sut.load()
        sut.submission.body = "追加で送ります"

        // Act
        await sut.submit()

        // Assert
        #expect(await sentArguments.values == [["inquiry", "request-1", "追加で送ります"]])
        #expect(updatedInquiries.value == [.makeForTest(id: "inquiry", updatedAt: Date(timeIntervalSince1970: 100))])
        #expect(sut.submission == InquirySubmission())
        let expected = InquiryDetailState(
            inquiry: .makeForTest(id: "inquiry", updatedAt: Date(timeIntervalSince1970: 100)),
            messages: [.makeForTest(id: "1"), .makeForTest(id: "2")]
        )
        #expect(sut.state == expected)
    }

    @Test("送信に失敗すると、入力とrequestIdを残し、送り直しでは同じrequestIdを使う")
    func submit_failureThenRetryWithSameRequestId() async {
        // Arrange
        let requestIds = TestLockedArray<String>()
        let generatedCount = TestBox(value: 0)
        let sut = InquiryDetailStore(
            inquiryId: "inquiry",
            inquiryClient: .init(sendMessage: { _, requestId, _ in
                await requestIds.append(requestId)
                throw DomainError.noNetwork
            }),
            makeRequestId: {
                generatedCount.value += 1
                return "request-\(generatedCount.value)"
            }
        )
        sut.submission.body = "追加で送ります"
        await sut.submit()

        // Act
        await sut.submit()

        // Assert
        #expect(await requestIds.values == ["request-1", "request-1"])
        let expected = InquirySubmission(
            body: "追加で送ります",
            failure: .domain(.noNetwork),
            requestId: "request-1"
        )
        #expect(sut.submission == expected)
    }

}
