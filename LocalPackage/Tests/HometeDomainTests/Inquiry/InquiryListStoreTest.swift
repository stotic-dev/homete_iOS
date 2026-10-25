//
//  InquiryListStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct InquiryListStoreTest {

    // MARK: - refresh

    @Test("先頭のページを取得すると、一覧・未読の件数・次のページの位置が入る")
    func refresh_success() async {
        // Arrange
        let sut = InquiryListStore(inquiryClient: .init(list: { cursor in
            #expect(cursor == nil)
            return .init(
                inquiries: [.makeForTest(id: "1", hasUnreadReply: true), .makeForTest(id: "2")],
                nextCursor: "next",
                unreadCount: 3
            )
        }))

        // Act
        await sut.refresh()

        // Assert
        let expected = InquiryListState(
            inquiries: [.makeForTest(id: "1", hasUnreadReply: true), .makeForTest(id: "2")],
            unreadCount: 3,
            nextCursor: "next",
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

    @Test("取り直すと、読み込み済みの次のページは捨てて先頭のページだけにする")
    func refresh_replacesLoadedPages() async {
        // Arrange
        let pages = TestBox(value: [
            InquiryListPage(inquiries: [.makeForTest(id: "1")], nextCursor: "next", unreadCount: 0),
            InquiryListPage(inquiries: [.makeForTest(id: "2")], nextCursor: nil, unreadCount: 0),
            InquiryListPage(inquiries: [.makeForTest(id: "3")], nextCursor: "next", unreadCount: 1),
        ])
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            pages.value.removeFirst()
        }))
        await sut.refresh()
        await sut.loadMore()

        // Act
        await sut.refresh()

        // Assert
        let expected = InquiryListState(
            inquiries: [.makeForTest(id: "3")],
            unreadCount: 1,
            nextCursor: "next",
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

    @Test("取り直しに失敗しても、取得済みの一覧は残して失敗の理由を入れる")
    func refresh_failureKeepsLoadedInquiries() async {
        // Arrange
        let shouldFail = TestBox(value: false)
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            if shouldFail.value {
                throw DomainError.noNetwork
            }
            return .init(inquiries: [.makeForTest(id: "1")], nextCursor: nil, unreadCount: 0)
        }))
        await sut.refresh()
        shouldFail.value = true

        // Act
        await sut.refresh()

        // Assert
        let expected = InquiryListState(
            inquiries: [.makeForTest(id: "1")],
            hasLoaded: true,
            loadFailure: .noNetwork
        )
        #expect(sut.state == expected)
    }

    @Test("取得中にもう一度取り直しても、取得は1回だけにする")
    func refresh_ignoresWhileRefreshing() async {
        // Arrange
        let gate = TestGate()
        let listCount = TestCounter()
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            await listCount.increment()
            await gate.wait()
            return .init(inquiries: [], nextCursor: nil, unreadCount: 0)
        }))
        let firstRefresh = Task { await sut.refresh() }
        await gate.waitUntilArrived()

        // Act
        await sut.refresh()

        // Assert
        gate.open()
        await firstRefresh.value
        #expect(await listCount.value == 1)
    }

    // MARK: - loadMore

    @Test("次のページを取得すると、前のページに無い問い合わせだけを末尾に足す")
    func loadMore_appendsWithoutDuplicates() async {
        // Arrange
        let sut = InquiryListStore(inquiryClient: .init(list: { cursor in
            if cursor == "next" {
                // ページをめくる間に更新された問い合わせが、次のページにも含まれる
                return .init(
                    inquiries: [.makeForTest(id: "2"), .makeForTest(id: "3")],
                    nextCursor: nil,
                    unreadCount: 0
                )
            }
            return .init(inquiries: [.makeForTest(id: "1"), .makeForTest(id: "2")], nextCursor: "next", unreadCount: 0)
        }))
        await sut.refresh()

        // Act
        await sut.loadMore()

        // Assert
        let expected = InquiryListState(
            inquiries: [.makeForTest(id: "1"), .makeForTest(id: "2"), .makeForTest(id: "3")],
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

    @Test("最後のページまで取得済みなら、次のページを取りにいかない")
    func loadMore_noMorePages() async {
        // Arrange
        let listCount = TestCounter()
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            await listCount.increment()
            return .init(inquiries: [.makeForTest(id: "1")], nextCursor: nil, unreadCount: 0)
        }))
        await sut.refresh()

        // Act
        await sut.loadMore()

        // Assert
        #expect(await listCount.value == 1)
    }

    // MARK: - apply

    @Test("未読の返信を既読にした問い合わせを反映すると、未読の件数を1つ減らす")
    func apply_markedRead() async {
        // Arrange
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            .init(inquiries: [.makeForTest(id: "1", hasUnreadReply: true)], nextCursor: nil, unreadCount: 1)
        }))
        await sut.refresh()

        // Act
        sut.apply(.makeForTest(id: "1"))

        // Assert
        let expected = InquiryListState(inquiries: [.makeForTest(id: "1")], hasLoaded: true)
        #expect(sut.state == expected)
    }

    @Test("メッセージを送って更新日時が新しくなった問い合わせは、一覧の先頭へ移す")
    func apply_movesUpdatedInquiryToTop() async {
        // Arrange
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            .init(
                inquiries: [
                    .makeForTest(id: "1", updatedAt: Date(timeIntervalSince1970: 200)),
                    .makeForTest(id: "2", updatedAt: Date(timeIntervalSince1970: 100)),
                ],
                nextCursor: nil,
                unreadCount: 0
            )
        }))
        await sut.refresh()

        // Act
        sut.apply(.makeForTest(id: "2", updatedAt: Date(timeIntervalSince1970: 300)))

        // Assert
        let expected = InquiryListState(
            inquiries: [
                .makeForTest(id: "2", updatedAt: Date(timeIntervalSince1970: 300)),
                .makeForTest(id: "1", updatedAt: Date(timeIntervalSince1970: 200)),
            ],
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

    @Test("作ったばかりの問い合わせを反映すると、一覧の先頭に足す")
    func apply_insertsNewInquiry() async {
        // Arrange
        let sut = InquiryListStore(inquiryClient: .init(list: { _ in
            .init(
                inquiries: [.makeForTest(id: "1", updatedAt: Date(timeIntervalSince1970: 100))],
                nextCursor: nil,
                unreadCount: 0
            )
        }))
        await sut.refresh()

        // Act
        sut.apply(.makeForTest(id: "2", updatedAt: Date(timeIntervalSince1970: 200)))

        // Assert
        let expected = InquiryListState(
            inquiries: [
                .makeForTest(id: "2", updatedAt: Date(timeIntervalSince1970: 200)),
                .makeForTest(id: "1", updatedAt: Date(timeIntervalSince1970: 100)),
            ],
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

}
