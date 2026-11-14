//
//  HouseworkCompleteBehaviorTests.swift
//  AgentToolsPackage
//

import HometeDomain
import HometeIntrospection
import HometeScenarioSupport
import Testing

@MainActor
struct HouseworkCompleteBehaviorTests {

    // 未完了の家事は、ポイントの大きい順に並ぶ（`HouseworkItem+IncompleteDisplayOrder`）
    private let laundry = HouseworkSnapshot(id: "laundry", title: "洗濯", point: 10)
    private let cleaning = HouseworkSnapshot(id: "cleaning", title: "掃除", point: 20)

    @Test("今日の家事を、パートナーと分けて「がんばった」で完了にすると、演出の後にシートが閉じて未完了から外れる")
    func completeWithPartner() async throws {
        // Arrange

        let driver = BehaviorDriver(.today)
        try driver.perform("complete", ["id": "laundry"])
        try driver.perform("selectEffort", ["effort": "hard"])
        try driver.perform("toggleMember", ["userId": "partner"])
        try await driver.performAndSettle("save")

        // Act

        try await driver.performAndSettle("finishPraise")

        // Assert

        let expected = AppSnapshot(
            currentScreen: .todayHousework,
            todayHousework: .init(incomplete: [cleaning], completedCount: 2, totalCount: 3),
            houseworkComplete: nil,
            availableActions: todayActions(hasIncomplete: true)
        )
        #expect(driver.snapshot == expected)
        let written = await driver.backend.items.first { $0.id == "laundry" }
        // 10ptを「がんばった」の1.2倍にした12ptを、2人で6ptずつ分ける
        #expect(written?.executors == [
            .init(userId: "own", percentage: 50, point: 6),
            .init(userId: "partner", percentage: 50, point: 6),
        ])
    }

    @Test("完了にできた直後は、ほめる演出を出し、入力と閉じるボタンを出さない")
    func praiseAfterCompletion() async throws {
        // Arrange

        let driver = BehaviorDriver(.today)
        try driver.perform("complete", ["id": "laundry"])

        // Act

        try await driver.performAndSettle("save")

        // Assert

        let expected = AppSnapshot(
            currentScreen: .houseworkComplete,
            todayHousework: .init(incomplete: [cleaning], completedCount: 2, totalCount: 3),
            houseworkComplete: .init(
                houseworkId: "laundry",
                title: "洗濯",
                effort: "normal",
                selectableMemberIds: ["own", "partner"],
                executors: [.init(userId: "own", percentage: 100)],
                totalPoint: 10,
                completedPoint: 10
            ),
            availableActions: completionActions(completed: true)
        )
        #expect(driver.snapshot == expected)
    }

    @Test("書き込みに失敗したら、入力を残したまま失敗を出し、もう一度完了にできる")
    func completeFailsOnce() async throws {
        // Arrange

        let driver = BehaviorDriver(.completeFailsOnce)
        try driver.perform("complete", ["id": "laundry"])

        // Act

        try await driver.performAndSettle("save")

        // Assert

        let expected = AppSnapshot(
            currentScreen: .houseworkComplete,
            todayHousework: .init(incomplete: [cleaning, laundry], completedCount: 1, totalCount: 3),
            houseworkComplete: .init(
                houseworkId: "laundry",
                title: "洗濯",
                effort: "normal",
                selectableMemberIds: ["own", "partner"],
                executors: [.init(userId: "own", percentage: 100)],
                totalPoint: 10,
                error: "noNetwork"
            ),
            availableActions: completionActions(hasError: true)
        )
        #expect(driver.snapshot == expected)
    }

    @Test("閉じるボタンで閉じると、家事は未完了のまま残る")
    func closeWithoutCompleting() async throws {
        // Arrange

        let driver = BehaviorDriver(.today)
        try driver.perform("complete", ["id": "laundry"])

        // Act

        try await driver.performAndSettle("close")

        // Assert

        let expected = AppSnapshot(
            currentScreen: .todayHousework,
            todayHousework: .init(incomplete: [cleaning, laundry], completedCount: 1, totalCount: 3),
            houseworkComplete: nil,
            availableActions: todayActions(hasIncomplete: true)
        )
        #expect(driver.snapshot == expected)
    }

    @Test("シートを出している間は、背景の「今日の家事」の操作を受け付けない")
    func backgroundActionNotAvailable() throws {
        // Arrange

        let driver = BehaviorDriver(.today)
        try driver.perform("complete", ["id": "laundry"])

        // Act

        let error = #expect(throws: IntrospectionError.self) {
            try driver.perform("complete", ["id": "cleaning"])
        }

        // Assert

        #expect(error?.code == .actionNotAvailable)
    }

    @Test("今日の家事が無いときは、操作が並ばない")
    func emptyHasNoActions() {
        // Act

        let driver = BehaviorDriver(.empty)

        // Assert

        let expected = AppSnapshot(
            currentScreen: .todayHousework,
            todayHousework: .init(incomplete: [], completedCount: 0, totalCount: 0),
            houseworkComplete: nil,
            availableActions: []
        )
        #expect(driver.snapshot == expected)
    }

}
