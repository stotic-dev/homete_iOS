//
//  HouseworkTemplateApplyStore.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/09.
//

import Foundation
import HometeDomain
import Observation

@MainActor
@Observable
final class HouseworkTemplateApplyStore {

    /// 上書き確認が必要な状態かどうか（適用範囲内に incomplete 家事が存在する場合に true）
    private(set) var isOverwriteConfirmationRequired: Bool = false

    private var pendingPlan: ApplyPlan?

    private let houseworkClient: HouseworkClient
    private let idGenerator: @MainActor @Sendable () -> String

    public init(
        houseworkClient: HouseworkClient = .previewValue,
        idGenerator: @escaping @MainActor @Sendable () -> String = { UUID().uuidString }
    ) {

        self.houseworkClient = houseworkClient
        self.idGenerator = idGenerator
    }

    /// 適用準備。適用範囲（now〜+6日）を計算し、incomplete 家事と突き合わせて上書き確認の要否を決める
    func prepareApply(
        days: [HouseworkTemplateDay],
        cohabitantId: String,
        incompleteItems: [HouseworkItem],
        now: Date,
        calendar: Calendar
    ) {

        let targetDates = (0...6).compactMap { offset in

            calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))
        }
        let targetIndexedDates = targetDates.map {

            HouseworkIndexedDate(value: $0)
        }
        let targetIncompleteItems = incompleteItems.filter { item in

            targetIndexedDates.contains(item.indexedDate)
        }
        pendingPlan = ApplyPlan(
            days: days,
            cohabitantId: cohabitantId,
            targetDates: targetDates,
            targetIncompleteItems: targetIncompleteItems,
            calendar: calendar
        )
        isOverwriteConfirmationRequired = !targetIncompleteItems.isEmpty
    }

    /// 適用を実行する。`prepareApply` 後に呼び出す。incomplete 家事を削除し、テンプレートアイテムを書き込む
    func executeApply() async throws {

        guard let plan = pendingPlan else { return }

        for item in plan.targetIncompleteItems {

            try await houseworkClient.removeItem(item, plan.cohabitantId)
        }

        for date in plan.targetDates {

            let weekday = plan.calendar.component(.weekday, from: date)
            let dayOfWeek = weekday - 1
            guard let templateDay = plan.days.first(where: { $0.dayOfWeek == dayOfWeek }) else {

                continue
            }
            let metaData = DailyHouseworkMetaData(selectedDate: date, calendar: plan.calendar)
            for templateItem in templateDay.items {

                let newItem = HouseworkItem(
                    id: idGenerator(),
                    title: templateItem.title,
                    point: templateItem.point,
                    metaData: metaData
                )
                try await houseworkClient.insertOrUpdateItem(newItem, plan.cohabitantId)
            }
        }

        reset()
    }

    /// 適用をキャンセルする（保留状態のplanを破棄）
    func cancelApply() {

        reset()
    }
}

private extension HouseworkTemplateApplyStore {

    func reset() {

        pendingPlan = nil
        isOverwriteConfirmationRequired = false
    }
}
