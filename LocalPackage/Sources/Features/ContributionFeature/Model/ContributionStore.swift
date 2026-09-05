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
public final class ContributionStore {

    // MARK: state

    private(set) var contiribution: HouseworkContribution = .init()
    /// スナップショットリスナーの購読状態
    public private(set) var loadState: ListenerLoadState = .loading

    // MARK: Dependencies

    private let houseworkManager: HouseworkManager
    private let calendar: Calendar

    private let observeKey = UUID().uuidString

    // MARK: initialize

    public init(
        houseworkManager: HouseworkManager = .init(houseworkClient: .previewValue),
        calendar: Calendar = .current
    ) {
        self.houseworkManager = houseworkManager
        self.calendar = calendar

        Task {
            await startObserving()
        }
    }

    /// 指定日まで遡って集計できるように、未取得の家事データを追加でフェッチする
    public func fetchIfNeeded(until targetDate: Date, cohabitantId: String, calendar: Calendar) async {
        await houseworkManager.fetchIfNeeded(
            until: targetDate,
            cohabitantId: cohabitantId,
            calendar: calendar
        )
    }

}

// MARK: private

private extension ContributionStore {

    func startObserving() async {
        let stream = await houseworkManager.createObserver(observeKey)
        for await result in stream {
            switch result {
            case let .success(items):
                await updatePoints(from: items)
                loadState = .loaded

            case let .failure(error):
                loadState = .failed(error)
            }
        }
    }

    func updatePoints(from items: [HouseworkItem]) async {
        let calendar = calendar
        let contribution = await Task.detached {
            // 貢献度のモデル生成は重い処理なのでバックグラウンドで実行する
            HouseworkContribution.make(by: items, calendar: calendar)
        }.value
        contiribution = contribution
    }

}
