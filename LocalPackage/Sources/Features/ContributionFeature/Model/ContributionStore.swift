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

    private(set) var contiribution: HouseworkContribution = .init()

    // MARK: Dependencies

    private let houseworkManager: HouseworkManager
    private let calendar: Calendar

    private let observeKey = "contributionStoreKey"

    // MARK: initialize

    init(
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        calendar: Calendar = .japanese
    ) {
        
        self.houseworkManager = houseworkManager
        self.calendar = calendar

        Task {
            await startObserving()
        }
    }
}

// MARK: private

private extension ContributionStore {

    func startObserving() async {
        let stream = await houseworkManager.createObserver(observeKey)
        for await items in stream {
            await updatePoints(from: items)
        }
    }

    func updatePoints(from items: [HouseworkItem]) async {
        self.contiribution = await Task.detached {
            // 貢献度のモデル生成は重い処理なのでバックグラウンドで実行する
            return HouseworkContribution.make(by: items, calendar: self.calendar)
        }.value
    }
}
