//
//  Scenario.swift
//  AgentToolsPackage
//

import Foundation
import HometeAppCore
import HometeDomain
import HometeIntrospection

/// CLI・行動テストの開始時点
public struct Scenario: Sendable {

    public let name: String
    public let summary: String
    private let items: @Sendable (_ today: Date) -> [HouseworkItem]
    private let writeFailures: Int

    public init(
        name: String,
        summary: String,
        writeFailures: Int = 0,
        items: @escaping @Sendable (_ today: Date) -> [HouseworkItem] = { _ in [] }
    ) {
        self.name = name
        self.summary = summary
        self.writeFailures = writeFailures
        self.items = items
    }

    /// このシナリオのfixtureと、それを使う`AgentSession`を作る
    @MainActor
    public func makeEnvironment() -> ScenarioEnvironment {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: Self.now)
        let items = items(today)
        let backend = FixtureHouseworkBackend(items: items, writeFailures: writeFailures)
        let client = backend.client
        let houseworkManager = HouseworkManager(
            houseworkClient: client,
            allItems: items,
            fetchedRange: today ... Self.now
        )
        let houseworkListStore = HouseworkListStore(
            houseworkClient: client,
            houseworkManager: houseworkManager,
            calendar: calendar,
            now: { Self.now },
            items: StoredAllHouseworkList.makeMultiDateList(items: items).value
        )
        let tasks = TaskTracker()
        let todayViewModel = TodayHouseworkViewModel(
            context: .init(now: Self.now, template: nil, members: Self.members, account: Self.account),
            houseworkListStore: houseworkListStore,
            calendar: calendar,
            tasks: tasks
        )
        return ScenarioEnvironment(
            backend: backend,
            session: AgentSession(today: todayViewModel, houseworkListStore: houseworkListStore, tasks: tasks)
        )
    }

}

public extension Scenario {

    /// 操作している本人
    static let account = Account(id: "own", userName: "たいち", cohabitantId: "fixture-cohabitant")
    /// グループのメンバー（自分とパートナー）
    static let members = CohabitantMemberList(
        value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
        ownId: "own"
    )
    /// シナリオの現在日時（2026/1/1 12:00 JST）
    static let now = Date(timeIntervalSince1970: 1_767_236_400)

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    static let empty = Scenario(name: "empty", summary: "今日の家事が無い")

    static let today = Scenario(
        name: "today",
        summary: "今日の家事が3件（洗濯・掃除が未完了、料理が完了済み）",
        items: todayItems
    )

    static let completeFailsOnce = Scenario(
        name: "complete-fails-once",
        summary: "todayと同じ。最初の書き込みだけ失敗する",
        writeFailures: 1,
        items: todayItems
    )

    static let all: [Scenario] = [.empty, .today, .completeFailsOnce]

    static func named(_ name: String) -> Scenario? {
        all.first { $0.name == name }
    }

}

private extension Scenario {

    static func todayItems(today: Date) -> [HouseworkItem] {
        [
            item(id: "laundry", title: "洗濯", point: 10, today: today, createdOrder: 0),
            item(id: "cleaning", title: "掃除", point: 20, today: today, createdOrder: 1),
            item(
                id: "cooking",
                title: "料理",
                point: 30,
                today: today,
                createdOrder: 2,
                state: .completed,
                executors: [.init(userId: "partner", percentage: 100, point: 30)]
            ),
        ]
    }

    static func item(
        id: String,
        title: String,
        point: Int,
        today: Date,
        createdOrder: Int,
        state: HouseworkState = .incomplete,
        executors: [HouseworkExecutor] = []
    ) -> HouseworkItem {
        HouseworkItem(
            id: id,
            indexedDate: .init(value: today),
            title: title,
            point: point,
            state: state,
            executors: executors,
            effort: .normal,
            executedAt: state == .completed ? today : nil,
            templateHouseworkItemId: nil,
            // 登録した順に並ぶよう、作った日時をずらす
            createdAt: today.addingTimeInterval(TimeInterval(createdOrder))
        )
    }

}

/// シナリオのfixtureと、それを使う`AgentSession`
public struct ScenarioEnvironment {

    public let backend: FixtureHouseworkBackend
    public let session: AgentSession

}
