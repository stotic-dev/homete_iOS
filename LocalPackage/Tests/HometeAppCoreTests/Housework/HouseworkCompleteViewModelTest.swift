//
//  HouseworkCompleteViewModelTest.swift
//  LocalPackage
//

import Foundation
@testable import HometeAppCore
import HometeDomain
import Testing

@MainActor
struct HouseworkCompleteViewModelTest {

    private let account = Account(id: "own", userName: "たいち", cohabitantId: "cohabitant")
    private let members = CohabitantMemberList(
        value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
        ownId: "own"
    )
    private let item = HouseworkBoardItem.makeForPreview(id: "laundry", title: "洗濯", point: 10)

    @Test("開いた直後は、自分だけを担当者に選び、頑張り度はふつうにする")
    func initialState() {
        // Act

        let viewModel = makeViewModel()

        // Assert

        let expected = HouseworkCompleteViewModel.State(allocation: .init(
            memberIds: ["own", "partner"],
            selectedIds: ["own"],
            basePoint: 10
        ))
        #expect(viewModel.state == expected)
    }

    @Test("完了にできたら、配ったポイントの合計でほめる演出に切り替え、家事を完了として書き込む")
    func completeSucceeded() async {
        // Arrange

        let written = TestBox<[HouseworkState]>(value: [])
        let viewModel = makeViewModel(houseworkClient: .init(insertOrUpdateItemHandler: { item, _ in
            written.value.append(item.state)
        }))
        viewModel.send(.effortSelected(.hard))

        // Act

        viewModel.send(.completeTapped)
        await tasks.waitUntilIdle()

        // Assert

        // 「がんばった」は1.2倍なので、10ptが12ptになる
        let expected = HouseworkCompleteViewModel.State(
            allocation: .init(memberIds: ["own", "partner"], selectedIds: ["own"], basePoint: 10, effort: .hard),
            completedPoint: 12
        )
        #expect(viewModel.state == expected)
        #expect(written.value == [.completed])
    }

    @Test("完了にできなかったら、入力を残したまま失敗を出す")
    func completeFailed() async {
        // Arrange

        let viewModel = makeViewModel(houseworkClient: .init(insertOrUpdateItemHandler: { _, _ in
            throw DomainError.noNetwork
        }))

        // Act

        viewModel.send(.completeTapped)
        await tasks.waitUntilIdle()

        // Assert

        let expected = HouseworkCompleteViewModel.State(
            allocation: .init(memberIds: ["own", "partner"], selectedIds: ["own"], basePoint: 10),
            error: .noNetwork
        )
        #expect(viewModel.state == expected)
    }

    @Test("完了にしている途中は、閉じる操作を受け付けない")
    func ignoresWhileCompleting() async {
        // Arrange

        var outcomes: [HouseworkCompleteViewModel.Outcome] = []
        let viewModel = makeViewModel(onFinish: { outcomes.append($0) })
        viewModel.send(.completeTapped)

        // Act

        viewModel.send(.closeTapped)

        // Assert

        let expected = HouseworkCompleteViewModel.State(
            allocation: .init(memberIds: ["own", "partner"], selectedIds: ["own"], basePoint: 10),
            isCompleting: true
        )
        #expect(viewModel.state == expected)
        #expect(outcomes.isEmpty)
        await tasks.waitUntilIdle()
    }

    @Test("閉じたあとに届いた完了の結果は反映しない")
    func ignoresResultAfterClose() async {
        // Arrange

        let viewModel = makeViewModel()
        viewModel.send(.completeTapped)

        // Act

        viewModel.close()
        await tasks.waitUntilIdle()

        // Assert

        let expected = HouseworkCompleteViewModel.State(
            allocation: .init(memberIds: ["own", "partner"], selectedIds: ["own"], basePoint: 10),
            isCompleting: true
        )
        #expect(viewModel.state == expected)
    }

    @Test(
        "ほめる演出を見せ終わる・完了の後に閉じると完了、完了の前に閉じるとキャンセルとして親へ伝える",
        arguments: [
            (
                completes: true,
                action: HouseworkCompleteViewModel.Action.praiseFinished,
                expected: [HouseworkCompleteViewModel.Outcome.completed]
            ),
            (completes: true, action: .closeTapped, expected: [.completed]),
            (completes: false, action: .closeTapped, expected: [.cancelled]),
            (completes: false, action: .praiseFinished, expected: []),
        ]
    )
    func outcome(
        completes: Bool,
        action: HouseworkCompleteViewModel.Action,
        expected: [HouseworkCompleteViewModel.Outcome]
    ) async {
        // Arrange

        var outcomes: [HouseworkCompleteViewModel.Outcome] = []
        let viewModel = makeViewModel(onFinish: { outcomes.append($0) })
        if completes {
            viewModel.send(.completeTapped)
            await tasks.waitUntilIdle()
        }

        // Act

        viewModel.send(action)

        // Assert

        #expect(outcomes == expected)
    }

    // MARK: - Helper

    private let tasks = TaskTracker()

    private func makeViewModel(
        houseworkClient: HouseworkClient = .previewValue,
        onFinish: @escaping @MainActor (HouseworkCompleteViewModel.Outcome) -> Void = { _ in }
    ) -> HouseworkCompleteViewModel {
        HouseworkCompleteViewModel(
            item: item,
            step: .dashboard,
            members: members,
            account: account,
            houseworkListStore: HouseworkListStore(houseworkClient: houseworkClient),
            now: { .previewDate(year: 2026, month: 1, day: 1) },
            tasks: tasks,
            onFinish: onFinish
        )
    }

}
