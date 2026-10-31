//
//  AnnouncementStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct AnnouncementStoreTest {

    // MARK: - refresh

    @Test("取得すると、一覧・未読の数・起動時に出すお知らせが入る")
    func refresh_success() async {
        // Arrange
        let sut = AnnouncementStore(announcementClient: .init(list: {
            .init(
                announcements: [
                    .makeForTest(id: "2", publishedAt: 200, isUnread: true),
                    .makeForTest(id: "1", publishedAt: 100),
                ],
                unreadCount: 1,
                modalAnnouncementId: "2"
            )
        }))

        // Act
        await sut.refresh()

        // Assert
        let expected = AnnouncementState(
            announcements: [
                .makeForTest(id: "2", publishedAt: 200, isUnread: true),
                .makeForTest(id: "1", publishedAt: 100),
            ],
            unreadCount: 1,
            modalAnnouncement: .makeForTest(id: "2", publishedAt: 200, isUnread: true),
            hasLoaded: true
        )
        #expect(sut.state == expected)
    }

    @Test("取り直しに失敗しても、取得済みの内容は残して失敗の理由を入れる")
    func refresh_failureKeepsLoadedAnnouncements() async {
        // Arrange
        let shouldFail = TestBox(value: false)
        let sut = AnnouncementStore(announcementClient: .init(list: {
            if shouldFail.value {
                throw DomainError.noNetwork
            }
            return .init(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: nil
            )
        }))
        await sut.refresh()
        shouldFail.value = true

        // Act
        await sut.refresh()

        // Assert
        let expected = AnnouncementState(
            announcements: [.makeForTest(id: "1", publishedAt: 100)],
            hasLoaded: true,
            loadFailure: .noNetwork
        )
        #expect(sut.state == expected)
    }

    @Test("取得中にもう一度呼ばれたら、新しく取りにいかずに進行中の取得を待つ")
    func refresh_whileRefreshing_waitsForInFlightRefresh() async {
        // Arrange
        let callCount = TestBox(value: 0)
        let (gate, openGate) = AsyncStream<Void>.makeStream()
        let sut = AnnouncementStore(announcementClient: .init(list: {
            callCount.value += 1
            for await _ in gate {
                break
            }
            return .init(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: nil
            )
        }))
        let first = Task {
            await sut.refresh()
        }
        while !sut.state.isRefreshing {
            await Task.yield()
        }

        // Act
        let second = Task {
            await sut.refresh()
            return sut.state.hasLoaded
        }
        await Task.yield()
        openGate.yield()
        await first.value
        let hasLoadedWhenSecondReturned = await second.value

        // Assert
        #expect(callCount.value == 1)
        #expect(hasLoadedWhenSecondReturned)
    }

    // MARK: - markListRead

    @Test("一覧を開くと先頭のお知らせを一覧で既読にし、未読の数とモーダルを消す。各お知らせの未読はそのまま残す")
    func markListRead_marksLatestAndClearsBadgeAndModal() async {
        // Arrange
        let marked = TestBox(value: [(String, AnnouncementReadScope)]())
        let sut = AnnouncementStore(announcementClient: .init(
            list: {
                .init(
                    announcements: [
                        .makeForTest(id: "2", publishedAt: 200, isUnread: true),
                        .makeForTest(id: "1", publishedAt: 100, isUnread: true),
                    ],
                    unreadCount: 2,
                    modalAnnouncementId: "2"
                )
            },
            markRead: { id, scope in
                marked.value.append((id, scope))
            }
        ))
        await sut.refresh()

        // Act
        await sut.markListRead()

        // Assert
        let expected = AnnouncementState(
            announcements: [
                .makeForTest(id: "2", publishedAt: 200, isUnread: true),
                .makeForTest(id: "1", publishedAt: 100, isUnread: true),
            ],
            unreadCount: 0,
            modalAnnouncement: nil,
            hasLoaded: true
        )
        #expect(sut.state == expected)
        #expect(marked.value.map(\.0) == ["2"])
        #expect(marked.value.map(\.1) == [.list])
    }

    @Test("お知らせが1件も無ければ、既読にしない")
    func markListRead_noAnnouncements_doesNotMark() async {
        // Arrange
        let markCount = TestBox(value: 0)
        let sut = AnnouncementStore(announcementClient: .init(
            list: { .init(announcements: [], unreadCount: 0, modalAnnouncementId: nil) },
            markRead: { _, _ in markCount.value += 1 }
        ))
        await sut.refresh()

        // Act
        await sut.markListRead()

        // Assert
        #expect(markCount.value == 0)
    }

    @Test("既読にした位置より新しいお知らせが無ければ、もう一度は既読にしない")
    func markListRead_alreadyRead_doesNotMarkAgain() async {
        // Arrange
        let markCount = TestBox(value: 0)
        let sut = AnnouncementStore(announcementClient: .init(
            list: { .init(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: nil
            ) },
            markRead: { _, _ in markCount.value += 1 }
        ))
        await sut.refresh()
        await sut.markListRead()

        // Act
        await sut.markListRead()

        // Assert
        #expect(markCount.value == 1)
    }

    @Test("既読にできなかったら、次に一覧を開いたときにもう一度既読にし、取り直した未読の数も戻す")
    func markListRead_failure_marksAgainNextTime() async {
        // Arrange
        let marked = TestBox(value: [String]())
        let shouldFail = TestBox(value: true)
        let sut = AnnouncementStore(announcementClient: .init(
            list: {
                .init(
                    announcements: [.makeForTest(id: "1", publishedAt: 100, isUnread: true)],
                    unreadCount: 1,
                    modalAnnouncementId: nil
                )
            },
            markRead: { id, _ in
                marked.value.append(id)
                if shouldFail.value {
                    throw DomainError.noNetwork
                }
            }
        ))
        await sut.refresh()
        await sut.markListRead()
        await sut.refresh()
        let unreadCountAfterFailure = sut.state.unreadCount
        shouldFail.value = false

        // Act
        await sut.markListRead()

        // Assert
        #expect(unreadCountAfterFailure == 1)
        #expect(marked.value == ["1", "1"])
    }

    @Test("既読にする前の内容が後から返ってきても、既読にした位置より後に公開されたものだけを未読として数え、モーダルも出し直さない")
    func refresh_afterMarkListRead_ignoresStaleUnreadAndModal() async {
        // Arrange
        let lists = TestBox(value: [
            AnnouncementList(
                announcements: [.makeForTest(id: "2", publishedAt: 200, isUnread: true)],
                unreadCount: 1,
                modalAnnouncementId: "2"
            ),
            // 既読がまだ反映されていない内容に、新しいお知らせが1件増えている
            AnnouncementList(
                announcements: [
                    .makeForTest(id: "3", publishedAt: 300, isUnread: true),
                    .makeForTest(id: "2", publishedAt: 200, isUnread: true),
                ],
                unreadCount: 2,
                modalAnnouncementId: "2"
            ),
        ])
        let sut = AnnouncementStore(announcementClient: .init(list: {
            lists.value.removeFirst()
        }))
        await sut.refresh()
        await sut.markListRead()

        // Act
        await sut.refresh()

        // Assert
        #expect(sut.state.unreadCount == 1)
        #expect(sut.state.modalAnnouncement == nil)
    }

    // MARK: - markModalRead

    @Test("モーダルを閉じるとそのお知らせをモーダルで既読にし、一覧の未読は残す")
    func markModalRead_marksModalAndKeepsUnreadCount() async {
        // Arrange
        let marked = TestBox(value: [(String, AnnouncementReadScope)]())
        let sut = AnnouncementStore(announcementClient: .init(
            list: {
                .init(
                    announcements: [.makeForTest(id: "1", publishedAt: 100, isUnread: true)],
                    unreadCount: 1,
                    modalAnnouncementId: "1"
                )
            },
            markRead: { id, scope in
                marked.value.append((id, scope))
            }
        ))
        await sut.refresh()

        // Act
        await sut.markModalRead()

        // Assert
        #expect(sut.state.modalAnnouncement == nil)
        #expect(sut.state.unreadCount == 1)
        #expect(marked.value.map(\.0) == ["1"])
        #expect(marked.value.map(\.1) == [.modal])
    }

    @Test("閉じたモーダルのお知らせが取り直しで返ってきても出し直さず、より新しいお知らせなら出す")
    func refresh_afterMarkModalRead_showsOnlyNewerModal() async {
        // Arrange
        let lists = TestBox(value: [
            AnnouncementList(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: "1"
            ),
            AnnouncementList(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: "1"
            ),
            AnnouncementList(
                announcements: [.makeForTest(id: "2", publishedAt: 200), .makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: "2"
            ),
        ])
        let sut = AnnouncementStore(announcementClient: .init(list: {
            lists.value.removeFirst()
        }))
        await sut.refresh()
        await sut.markModalRead()

        // Act
        await sut.refresh()
        let modalAfterStaleRefresh = sut.state.modalAnnouncement
        await sut.refresh()

        // Assert
        #expect(modalAfterStaleRefresh == nil)
        #expect(sut.state.modalAnnouncement == .makeForTest(id: "2", publishedAt: 200))
    }

    @Test("モーダルのお知らせが一覧に含まれていなければ、モーダルは出さない")
    func refresh_modalIdNotInList_noModal() async {
        // Arrange
        let sut = AnnouncementStore(announcementClient: .init(list: {
            .init(
                announcements: [.makeForTest(id: "1", publishedAt: 100)],
                unreadCount: 0,
                modalAnnouncementId: "unknown"
            )
        }))

        // Act
        await sut.refresh()

        // Assert
        #expect(sut.state.modalAnnouncement == nil)
    }

}
