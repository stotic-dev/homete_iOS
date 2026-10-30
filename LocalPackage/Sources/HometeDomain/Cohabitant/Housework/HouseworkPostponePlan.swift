//
//  HouseworkPostponePlan.swift
//  LocalPackage
//

import Foundation

/// 未完了の家事を別の日へまわすときに、書き込む家事と結果を決める
///
/// | まわす家事 | まわす先の日 | 書き込む家事 |
/// |---|---|---|
/// | 単発 | — | 同じドキュメントの日付を書き換える |
/// | テンプレート | 同じテンプレートの家事が未完了で出ている | 元の日の記録だけ（まわす先の家事にまとめる） |
/// | テンプレート | それ以外 | 元の日の記録と、まわす先の単発の家事 |
///
/// テンプレートの家事は仮想表示（ADR-0003）なので、元の日に記録を残さないとテンプレートからまた出てしまう。
/// 書き込む家事は1回の`WriteBatch`でまとめて書き、元の日だけ消えてまわす先に無い状態を作らない。
public struct HouseworkPostponePlan: Equatable, Sendable {

    public enum Outcome: Equatable, Sendable {

        /// 単発の家事として移した
        case moved
        /// まわす先の同じテンプレートの家事にまとめた
        case merged

    }

    /// 書き込む家事
    public let writes: [HouseworkItem]
    public let outcome: Outcome
    /// まわす先にある、同じ名前の家事の名前。確認のアラートに使う。まとめるとき・無いときは`nil`
    public let conflictingTitle: String?

}

public extension HouseworkPostponePlan {

    /// - Parameters:
    ///   - target: まわす家事。登録済みの家事なら、リスナーで受け取った最新の記録を渡す
    ///   - isRegistered: まわす家事がFirestoreに登録済みか（テンプレートから出している家事は未登録）
    ///   - destination: まわす先の日
    ///   - storedItems: 登録済みの家事。まわす先の日の家事を探すのに使う
    ///   - templateContext: テンプレート。まわす先の日にテンプレートから出る家事を探すのに使う
    ///   - now: 新しく作るドキュメントの作成日時
    ///   - storagePolicy: まわす先の日付から保持期限を求めるのに使う
    ///   - newItemId: まわす先に単発の家事を作るときのID（作らないときは使わない）
    static func make( // swiftlint:disable:this function_parameter_count
        target: HouseworkItem,
        isRegistered: Bool,
        destination: Date,
        storedItems: StoredAllHouseworkList,
        templateContext: HouseworkTemplateContext,
        now: Date,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy,
        newItemId: String
    ) -> Self {
        let metaData = DailyHouseworkMetaData(
            selectedDate: destination,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
        let destinationItems = Self.items(
            on: metaData.indexedDate.value,
            storedItems: storedItems,
            templateContext: templateContext,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
        let conflictingTitle = destinationItems.contains { $0.title == target.title && $0.id != target.id }
            ? target.title
            : nil

        guard let templateItemId = target.templateHouseworkItemId else {
            return .init(writes: [target.postponed(to: metaData)], outcome: .moved, conflictingTitle: conflictingTitle)
        }

        let markedTarget = target.markedAsPostponed(to: metaData.indexedDate)
        // テンプレートから出している家事は、まだドキュメントが無いので作成日時を付けて新しく作る
        let originalRecord = isRegistered ? markedTarget : markedTarget.updateCreatedAt(now)
        let canMerge = destinationItems.contains {
            $0.templateHouseworkItemId == templateItemId && $0.state == .incomplete
        }
        if canMerge {
            return .init(writes: [originalRecord], outcome: .merged, conflictingTitle: nil)
        }
        return .init(
            writes: [originalRecord, target.makePostponedCopy(id: newItemId, to: metaData, at: now)],
            outcome: .moved,
            conflictingTitle: conflictingTitle
        )
    }

}

private extension HouseworkPostponePlan {

    /// その日の家事を、テンプレートから出る家事も含めて返す（元の日に残した記録は含めない）
    static func items(
        on day: Date,
        storedItems: StoredAllHouseworkList,
        templateContext: HouseworkTemplateContext,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy
    ) -> [HouseworkItem] {
        let registeredItems = storedItems.value
            .first { $0.metaData.indexedDate.value == day }?
            .items ?? []
        guard let template = templateContext.templateOfDay(by: day, calendar: calendar) else {
            return registeredItems.filter { !$0.isPostponedRecord }
        }
        // IDは名前の比較とテンプレートIDの照合にしか使わないため、テンプレートの家事のIDをそのまま使う
        return template.applyTemplate(
            registeredItems: registeredItems,
            selectedDate: day,
            calendar: calendar,
            storagePolicy: storagePolicy,
            idGenerator: { "template-\($0.id.id)" }
        )
    }

}
