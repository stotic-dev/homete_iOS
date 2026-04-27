//
//  ContributionStore.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/27.
//

import Foundation
import HometeDomain
import Observation

@MainActor
@Observable
final class ContributionStore {

    // MARK: state

    private(set) var pointSummaries: [PointSummary] = []
    private(set) var weeklyPoints: [PointOfWeek] = []
    private(set) var monthlyPoints: [PointOfMonth] = []
    private(set) var yearlyPoints: [PointOfYear] = []
    private(set) var selectedPeriod: DisplayPointPeriod.PeriodType = .month

    private let calendar: Calendar = .autoupdatingCurrent

    // MARK: Dependencies

    private let houseworkManager: HouseworkManager
    private let cohabitantStore: CohabitantStore
    private let accountStore: AccountStore

    private let observeKey = "contributionStoreKey"

    // MARK: initialize

    init(
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        cohabitantStore: CohabitantStore = .init(),
        accountStore: AccountStore = .init()
    ) {
        self.houseworkManager = houseworkManager
        self.cohabitantStore = cohabitantStore
        self.accountStore = accountStore

        Task {
            await startObserving()
        }
    }

    // MARK: internal

    func selectPeriod(_ periodType: DisplayPointPeriod.PeriodType) {
        selectedPeriod = periodType
    }

    /// executorId からユーザー名を解決する
    /// CohabitantStore → AccountStore の順にフォールバックし、未解決の場合は userId をそのまま返す
    func userName(for userId: String) -> String {
        if let name = cohabitantStore.members.userName(userId) {
            return name
        }
        if let account = accountStore.account, account.id == userId {
            return account.userName
        }
        return userId
    }
}

// MARK: private

private extension ContributionStore {

    func startObserving() async {
        let stream = await houseworkManager.createObserver(observeKey)
        for await items in stream {
            updatePoints(from: items)
        }
    }

    func allUserIds() -> [String] {
        cohabitantStore.members.value.map(\.id)
    }

    func updatePoints(from items: [HouseworkItem]) {
        let currentDate = Date.now
        let userIds = allUserIds()
        let contribution = HouseworkContribution.make(by: items, calendar: calendar)

        pointSummaries = contribution.calculatePointSummaries(
            allUserIds: userIds,
            month: currentDate,
            calendar: calendar
        )

        let weekPeriod = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        let monthPeriod = calendar.dateComponents([.year, .month], from: currentDate)
        let yearPeriod = calendar.dateComponents([.year], from: currentDate)

        weeklyPoints = contribution.viewablePointList(
            allUserIdList: userIds,
            period: weekPeriod,
            calendar: calendar
        )
        monthlyPoints = contribution.viewablePointList(
            allUserIdList: userIds,
            period: monthPeriod,
            calendar: calendar
        )
        yearlyPoints = contribution.viewablePointList(
            allUserIdList: userIds,
            period: yearPeriod,
            calendar: calendar
        )
    }
}
