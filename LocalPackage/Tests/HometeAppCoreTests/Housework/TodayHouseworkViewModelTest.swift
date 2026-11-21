//
//  TodayHouseworkViewModelTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeAppCore
import HometeDomain
import Testing

@MainActor
struct TodayHouseworkViewModelTest {

    private let today = Date.previewDate(year: 2026, month: 1, day: 1)
    private let account = Account(id: "own", userName: "たいち", cohabitantId: "cohabitant")
    private let members = CohabitantMemberList(value: [.init(id: "own", userName: "たいち")], ownId: "own")
    private let laundry = HouseworkItem.makeForTest(
        id: "laundry",
        indexedDate: .previewDate(year: 2026, month: 1, day: 1),
        title: "洗濯",
        point: 10
    )
    private let cleaning = HouseworkItem.makeForTest(
        id: "cleaning",
        indexedDate: .previewDate(year: 2026, month: 1, day: 1),
        title: "掃除",
        point: 20
    )

    @Test("今日の未完了の家事の「完了にする」を押すと、その家事を完了にするシートを開いた直後の状態で出す")
    func completeTappedPresentsCompletion() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])

        // Act

        viewModel.send(.completeTapped(itemId: "laundry"))

        // Assert

        let expectedItem = HouseworkBoardItem(originalItem: laundry, isRegistered: true)
        let expectedState = HouseworkCompleteViewModel.State(
            allocation: .init(memberIds: ["own"], selectedIds: ["own"], basePoint: 10)
        )
        #expect(viewModel.completion?.item == expectedItem)
        #expect(viewModel.completion?.state == expectedState)
    }

    @Test("今日の未完了の家事に無いIDでは、シートを出さない")
    func completeTappedIgnoresUnknownItem() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])

        // Act

        viewModel.send(.completeTapped(itemId: "unknown"))

        // Assert

        #expect(viewModel.completion == nil)
    }

    @Test("別の家事のシートを出している間は、「完了にする」を受け付けない")
    func completeTappedIgnoredWhilePresenting() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry, cleaning])
        viewModel.send(.completeTapped(itemId: "laundry"))
        let completion = viewModel.completion

        // Act

        viewModel.send(.completeTapped(itemId: "cleaning"))

        // Assert

        #expect(viewModel.completion === completion)
    }

    @Test("完了にして演出を見せ終わると、シートを閉じる")
    func praiseFinishedClosesCompletion() async {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])
        viewModel.send(.completeTapped(itemId: "laundry"))
        viewModel.completion?.send(.completeTapped)
        await tasks.waitUntilIdle()

        // Act

        viewModel.completion?.send(.praiseFinished)

        // Assert

        #expect(viewModel.completion == nil)
    }

    @Test("完了にする前に下へスワイプすると、シートを閉じ、シートのViewModelも閉じる")
    func dismissClosesCompletion() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])
        viewModel.send(.completeTapped(itemId: "laundry"))
        let completion = viewModel.completion

        // Act

        viewModel.send(.completionDismissed)

        // Assert

        #expect(viewModel.completion == nil)
        #expect(completion?.isClosed == true)
    }

    @Test("完了にしている途中は、下へスワイプしてもシートを閉じない")
    func dismissIgnoredWhileCompleting() async {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])
        viewModel.send(.completeTapped(itemId: "laundry"))
        let completion = viewModel.completion
        completion?.send(.completeTapped)

        // Act

        viewModel.send(.completionDismissed)

        // Assert

        #expect(viewModel.completion === completion)
        await tasks.waitUntilIdle()
    }

    @Test("日付が変わると、その日の家事で一覧を組み立て直す")
    func contextChangedRebuildsSummary() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])

        // Act

        viewModel.send(.contextChanged(.init(
            now: .previewDate(year: 2026, month: 1, day: 2),
            template: nil,
            members: members,
            account: account
        )))

        // Assert

        #expect(viewModel.summary.incompleteItems == [])
    }

    // MARK: - Helper

    private let tasks = TaskTracker()

    private func makeViewModel(items: [HouseworkItem]) -> TodayHouseworkViewModel {
        TodayHouseworkViewModel(
            context: .init(now: today, template: nil, members: members, account: account),
            houseworkListStore: HouseworkListStore(items: [
                .init(items: items, metaData: .init(indexedDate: .init(value: today))),
            ]),
            calendar: .japanese,
            tasks: tasks
        )
    }

}
