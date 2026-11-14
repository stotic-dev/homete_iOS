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
    private let laundry = HouseworkItem.makeForTest(
        id: "laundry",
        indexedDate: .previewDate(year: 2026, month: 1, day: 1),
        title: "洗濯",
        point: 10
    )

    @Test("今日の未完了の家事の「完了にする」を押すと、その家事を完了にするシートを出す")
    func completeTappedPresentsCompletion() {
        // Arrange

        let viewModel = makeViewModel(items: [laundry])

        // Act

        viewModel.send(.completeTapped(itemId: "laundry"))

        // Assert

        #expect(viewModel.completion?.item == HouseworkBoardItem(originalItem: laundry, isRegistered: true))
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

    // MARK: - Helper

    private let tasks = TaskTracker()

    private func makeViewModel(items: [HouseworkItem]) -> TodayHouseworkViewModel {
        TodayHouseworkViewModel(
            context: .init(
                now: today,
                template: nil,
                members: .init(value: [.init(id: "own", userName: "たいち")], ownId: "own"),
                account: account
            ),
            houseworkListStore: HouseworkListStore(items: [
                .init(items: items, metaData: .init(indexedDate: .init(value: today))),
            ]),
            calendar: .japanese,
            tasks: tasks
        )
    }

}
