//
//  AppReviewPolicy.swift
//  LocalPackage
//

import Foundation

/// アプリの評価をリクエストするかどうかを判定する
///
/// 同じきっかけは1回だけ、どのきっかけでも前回のリクエストから一定期間は空ける。
/// 期間を空けている間に条件を満たしても、そのきっかけは使い切らずに次の機会へ回す。
/// - Note: 判定と記録の更新だけを持つ。記録の保存・Analytics・`requestReview`の呼び出しは呼び出し側で行う
public struct AppReviewPolicy: Equatable, Sendable {

    public private(set) var state: AppReviewState

    /// - Parameters:
    ///   - savedState: 端末に保存していた記録。初めて判定するときは`nil`
    ///   - now: 初めて判定するときに、使い始めた日時とありがとうを数え始める日時にする
    ///          （それより前に届いていたありがとうは数えない）
    public init(savedState: AppReviewState?, now: Date) {
        state = savedState ?? .init(
            startedAt: now,
            thanksCountedUntil: now,
            thanksCountedKeysAtMarker: [],
            receivedThanksCount: .zero,
            requestedTriggers: [],
            lastRequestedAt: nil
        )
    }

    /// プランの変化から、課金をきっかけにリクエストするかを判定する
    /// - Note: 未取得（`nil`）からの変化は起動時の取得なので、課金とはみなさない
    public func purchaseTrigger(
        from oldValue: EntitlementInfo?,
        to newValue: EntitlementInfo?,
        now: Date
    ) -> AppReviewTrigger? {
        guard let oldValue, !oldValue.isActive, newValue?.isActive == true else { return nil }

        return canRequest(.purchase, now: now) ? .purchase : nil
    }

    /// 家事一覧から新しく受け取ったありがとうを数え、ありがとうをきっかけにリクエストするかを判定する
    ///
    /// 自分が担当した家事に、自分以外の人から届いたありがとうを数える。
    /// - Note: 両方の条件を満たしたときは合計の方を優先する。もう一方は次の機会に回る
    public mutating func receiveThanks(
        in items: StoredAllHouseworkList,
        accountId: String,
        now: Date
    ) -> AppReviewTrigger? {
        let newThanks = receivedThanks(in: items, accountId: accountId).filter(isNew)
        guard let latestSentAt = newThanks.map(\.sentAt).max() else { return nil }

        let marker = max(latestSentAt, state.thanksCountedUntil)
        let newKeysAtMarker = Set(newThanks.filter { $0.sentAt == marker }.map(\.key))
        state = .init(
            startedAt: state.startedAt,
            thanksCountedUntil: marker,
            // 目印が進んだら、前の目印で覚えていた分はもう判定に使わないので捨てる
            thanksCountedKeysAtMarker: marker == state.thanksCountedUntil
                ? state.thanksCountedKeysAtMarker.union(newKeysAtMarker)
                : newKeysAtMarker,
            receivedThanksCount: state.receivedThanksCount + newThanks.count,
            requestedTriggers: state.requestedTriggers,
            lastRequestedAt: state.lastRequestedAt
        )
        if state.receivedThanksCount >= Self.thanksCountThreshold, canRequest(.thanksCount, now: now) {
            return .thanksCount
        }
        if now.timeIntervalSince(state.startedAt) >= Self.usagePeriodForThanks,
           canRequest(.thanksAfterTwoWeeks, now: now) {
            return .thanksAfterTwoWeeks
        }
        return nil
    }

    /// リクエストしたことを記録する
    public mutating func markRequested(_ trigger: AppReviewTrigger, now: Date) {
        state = .init(
            startedAt: state.startedAt,
            thanksCountedUntil: state.thanksCountedUntil,
            thanksCountedKeysAtMarker: state.thanksCountedKeysAtMarker,
            receivedThanksCount: state.receivedThanksCount,
            requestedTriggers: state.requestedTriggers.union([trigger]),
            lastRequestedAt: now
        )
    }

}

private extension AppReviewPolicy {

    /// 自分が担当した家事に、自分以外の人から届いたありがとう
    func receivedThanks(in items: StoredAllHouseworkList, accountId: String) -> [ReceivedThanks] {
        items.value
            .flatMap(\.items)
            .filter { item in item.executors.contains { $0.userId == accountId } }
            .flatMap { item in
                item.thanks
                    .filter { $0.key != accountId }
                    .map { ReceivedThanks(key: .init(houseworkId: item.id, senderId: $0.key), sentAt: $0.value.sentAt) }
            }
    }

    /// まだ数えていないありがとうか
    func isNew(_ thanks: ReceivedThanks) -> Bool {
        thanks.sentAt > state.thanksCountedUntil
            || (thanks.sentAt == state.thanksCountedUntil && !state.thanksCountedKeysAtMarker.contains(thanks.key))
    }

    func canRequest(_ trigger: AppReviewTrigger, now: Date) -> Bool {
        guard !state.requestedTriggers.contains(trigger) else { return false }
        guard let lastRequestedAt = state.lastRequestedAt else { return true }

        return now.timeIntervalSince(lastRequestedAt) >= Self.requestInterval
    }

}

private struct ReceivedThanks {

    let key: AppReviewThanksKey
    let sentAt: Date

}

// MARK: constant

private extension AppReviewPolicy {

    /// 合計をきっかけにリクエストする、受け取ったありがとうの数
    static var thanksCountThreshold: Int {
        10
    }

    /// ありがとうをきっかけにリクエストするまでに、使い続けている必要がある期間（14日）
    static var usagePeriodForThanks: TimeInterval {
        14 * 24 * 60 * 60
    }

    /// 前回のリクエストから空ける期間（30日）
    static var requestInterval: TimeInterval {
        30 * 24 * 60 * 60
    }

}
