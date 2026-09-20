//
//  PasteboardInvitationStoreTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain
import Testing

@MainActor
struct PasteboardInvitationStoreTest {

    // MARK: - checkIfNeeded

    @Test("クリップボードにURLらしきものがあれば案内を出す")
    func checkIfNeeded_suggests() async {
        // Arrange
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(detectProbableWebURL: {
                .init(hasProbableWebURL: true, changeCount: 1)
            })
        )

        // Act
        await sut.checkIfNeeded()

        // Assert
        #expect(sut.state == .suggesting)
    }

    @Test("クリップボードにURLらしきものがなければ案内を出さない")
    func checkIfNeeded_idle() async {
        // Arrange
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(detectProbableWebURL: {
                .init(hasProbableWebURL: false, changeCount: 1)
            })
        )

        // Act
        await sut.checkIfNeeded()

        // Assert
        #expect(sut.state == .idle)
    }

    @Test("案内を出したときだけAnalyticsイベントを送り、再確認では送らない")
    func checkIfNeeded_logsOnce() async {
        // Arrange
        let logger = Box<[AnalyticsEvent]>(value: [])
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(detectProbableWebURL: {
                .init(hasProbableWebURL: true, changeCount: 1)
            }),
            analyticsClient: .init(log: { event in logger.value.append(event) })
        )

        // Act
        await sut.checkIfNeeded()
        await sut.checkIfNeeded()

        // Assert
        #expect(logger.value == [
            .cohabitantInvitation(.pasteboardChecked(isSuggested: true)),
        ])
    }

    // MARK: - readInvitation

    @Test("読み取った内容が招待リンクなら、参加待ちのトークンとして渡して案内を閉じる")
    func readInvitation_found() async {
        // Arrange
        let pendingInvitationStore = PendingInvitationStore()
        let logger = Box<[AnalyticsEvent]>(value: [])
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(
                detectProbableWebURL: { .init(hasProbableWebURL: true, changeCount: 1) },
                readURL: { URL(string: "https://homete-ios-dev-e3ef7.web.app/invite/test-token") }
            ),
            analyticsClient: .init(log: { event in logger.value.append(event) }),
            pendingInvitationStore: pendingInvitationStore
        )
        await sut.checkIfNeeded()

        // Act
        await sut.readInvitation()

        // Assert
        #expect(sut.state == .idle)
        #expect(pendingInvitationStore.pendingToken == "test-token")
        #expect(logger.value == [
            .cohabitantInvitation(.pasteboardChecked(isSuggested: true)),
            .cohabitantInvitation(.linkOpened(source: .pasteboard)),
        ])
    }

    @Test(
        "読み取った内容が招待リンクでなければ、見つからなかったことを表示しトークンは渡さない",
        arguments: [
            URL(string: "https://example.com/"),
            nil,
        ]
    )
    func readInvitation_notFound(url: URL?) async {
        // Arrange
        let pendingInvitationStore = PendingInvitationStore()
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(
                detectProbableWebURL: { .init(hasProbableWebURL: true, changeCount: 1) },
                readURL: { url }
            ),
            pendingInvitationStore: pendingInvitationStore
        )
        await sut.checkIfNeeded()

        // Act
        await sut.readInvitation()

        // Assert
        #expect(sut.state == .notFound)
        #expect(pendingInvitationStore.pendingToken == nil)
    }

    @Test("読み取り済みの内容は、再確認しても案内を出し直さない")
    func checkIfNeeded_afterRead_sameContent() async {
        // Arrange
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(
                detectProbableWebURL: { .init(hasProbableWebURL: true, changeCount: 1) },
                readURL: { URL(string: "https://example.com/") }
            )
        )
        await sut.checkIfNeeded()
        await sut.readInvitation()

        // Act
        await sut.checkIfNeeded()

        // Assert
        #expect(sut.state == .notFound)
    }

    @Test("読み取り後にクリップボードの内容が変わっていれば、改めて案内を出す")
    func checkIfNeeded_afterRead_changedContent() async {
        // Arrange
        let changeCount = Box(value: 1)
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(
                detectProbableWebURL: { .init(hasProbableWebURL: true, changeCount: changeCount.value) },
                readURL: { URL(string: "https://example.com/") }
            )
        )
        await sut.checkIfNeeded()
        await sut.readInvitation()
        changeCount.value = 2

        // Act
        await sut.checkIfNeeded()

        // Assert
        #expect(sut.state == .suggesting)
    }

    @Test("読み取り後にクリップボードが空になっていれば、見つからなかった表示を引っ込める")
    func checkIfNeeded_afterRead_cleared() async {
        // Arrange
        let detection = Box(value: PasteboardDetection(hasProbableWebURL: true, changeCount: 1))
        let sut = PasteboardInvitationStore(
            pasteboardClient: .init(
                detectProbableWebURL: { detection.value },
                readURL: { URL(string: "https://example.com/") }
            )
        )
        await sut.checkIfNeeded()
        await sut.readInvitation()
        detection.value = .init(hasProbableWebURL: false, changeCount: 2)

        // Act
        await sut.checkIfNeeded()

        // Assert
        #expect(sut.state == .idle)
    }

}

// MARK: - テスト用のヘルパー

/// `@Sendable`なクロージャから、テスト中に差し替え・記録したい値を出し入れするための箱
/// - Note: Storeが`@MainActor`で、クロージャもメインアクター上で順に呼ばれるため排他は不要
private final class Box<Value>: @unchecked Sendable {

    var value: Value

    init(value: Value) {
        self.value = value
    }

}
