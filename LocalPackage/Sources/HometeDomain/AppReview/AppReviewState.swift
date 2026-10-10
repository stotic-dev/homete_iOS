//
//  AppReviewState.swift
//  LocalPackage
//

import Foundation

/// 評価のリクエストを判定するために端末へ保存する記録
public struct AppReviewState: Equatable, Sendable, Codable {

    /// 使い始めた日時。この機能が入ったバージョンで初めて判定した日時
    public let startedAt: Date
    /// ありがとうをどこまで数えたか。`sentAt`がこれより新しいありがとうだけを新しく受け取った分として数える
    public let thanksCountedUntil: Date
    /// 受け取ったありがとうの累計
    public let receivedThanksCount: Int
    /// リクエストしたきっかけ
    public let requestedTriggers: Set<AppReviewTrigger>
    /// 最後にリクエストした日時
    public let lastRequestedAt: Date?

    public init(
        startedAt: Date,
        thanksCountedUntil: Date,
        receivedThanksCount: Int,
        requestedTriggers: Set<AppReviewTrigger>,
        lastRequestedAt: Date?
    ) {
        self.startedAt = startedAt
        self.thanksCountedUntil = thanksCountedUntil
        self.receivedThanksCount = receivedThanksCount
        self.requestedTriggers = requestedTriggers
        self.lastRequestedAt = lastRequestedAt
    }

}
