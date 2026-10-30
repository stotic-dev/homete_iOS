//
//  HouseworkListStore+Postpone.swift
//  LocalPackage
//

import Foundation
import HometeDomain

/// 家事を別の日へまわした結果
enum HouseworkPostponeResult: Equatable {

    /// まわした
    case postponed
    /// まわす前に確かめることがある。確認のアラートで了承されたら`postpone(_:...)`でまわす
    case needsConfirmation(HouseworkPostponeConfirmation)
    /// 画面を開いている間に同居人が完了・「やらない」にしていて、まわさなかった
    case skipped

}

extension HouseworkListStore {

    /// 家事を別の日へまわす。まとめるとき・同じ名前の家事があるときは、まわさずに確かめる内容を返す
    func postponeIfNeeded( // swiftlint:disable:this function_parameter_count
        _ item: HouseworkBoardItem,
        to destination: Date,
        templateContext: HouseworkTemplateContext,
        storagePolicy: HouseworkStoragePolicy,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> HouseworkPostponeResult {
        let plan = postponePlan(
            target: items.item(item.originalItem) ?? item.originalItem,
            isRegistered: item.isRegistered,
            to: destination,
            templateContext: templateContext,
            storagePolicy: storagePolicy
        )
        if let confirmation = HouseworkPostponeConfirmation(item: item, destination: destination, plan: plan) {
            return .needsConfirmation(confirmation)
        }
        return try await write(
            item,
            to: destination,
            templateContext: templateContext,
            storagePolicy: storagePolicy,
            cohabitantId: cohabitantId,
            step: step
        )
    }

    /// 確認のアラートで了承された家事を、別の日へまわす
    func postpone(
        _ confirmation: HouseworkPostponeConfirmation,
        templateContext: HouseworkTemplateContext,
        storagePolicy: HouseworkStoragePolicy,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> HouseworkPostponeResult {
        try await write(
            confirmation.item,
            to: confirmation.destination,
            templateContext: templateContext,
            storagePolicy: storagePolicy,
            cohabitantId: cohabitantId,
            step: step
        )
    }

    /// クイックアクションでまわす先の日（家事の日付の翌日）
    static func nextDay(of item: HouseworkBoardItem, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: item.originalItem.indexedDate.value))
    }

}

private extension HouseworkListStore {

    /// まわす先の判定は、書き込む直前にリスナーで受け取った最新の記録で`postpone(target:...)`がやり直す
    func write( // swiftlint:disable:this function_parameter_count
        _ item: HouseworkBoardItem,
        to destination: Date,
        templateContext: HouseworkTemplateContext,
        storagePolicy: HouseworkStoragePolicy,
        cohabitantId: String,
        step: HouseworkAnalyticsStep
    ) async throws -> HouseworkPostponeResult {
        let outcome = try await postpone(
            target: item.originalItem,
            isRegistered: item.isRegistered,
            to: destination,
            templateContext: templateContext,
            storagePolicy: storagePolicy,
            cohabitantId: cohabitantId,
            step: step
        )
        return outcome == nil ? .skipped : .postponed
    }

}
