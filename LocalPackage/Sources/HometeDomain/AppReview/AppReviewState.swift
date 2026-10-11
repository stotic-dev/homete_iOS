//
//  AppReviewState.swift
//  LocalPackage
//

import Foundation

/// 評価のリクエストを判定するために端末へ保存する記録
public struct AppReviewState: Equatable, Sendable, Codable {

    /// 使い始めた日時。この機能が入ったバージョンで初めて判定した日時
    public let startedAt: Date
    /// ありがとうをどこまで数えたか。`sentAt`がこれより新しいありがとうを新しく受け取った分として数える
    public let thanksCountedUntil: Date
    /// `sentAt`が`thanksCountedUntil`と同じで、数え済みのありがとう（`AppReviewThanksKey`）
    /// - Note: 一括操作で送ったありがとうは`sentAt`がすべて同じになり、1件ずつ別のスナップショットで届く。
    ///         日時だけで判定すると2件目以降を数え漏らすため、目印と同じ日時の分は個別に覚えておく
    public let thanksCountedKeysAtMarker: Set<AppReviewThanksKey>
    /// 受け取ったありがとうの累計
    public let receivedThanksCount: Int
    /// リクエストしたきっかけ
    public let requestedTriggers: Set<AppReviewTrigger>
    /// 最後にリクエストした日時
    public let lastRequestedAt: Date?

    public init(
        startedAt: Date,
        thanksCountedUntil: Date,
        thanksCountedKeysAtMarker: Set<AppReviewThanksKey>,
        receivedThanksCount: Int,
        requestedTriggers: Set<AppReviewTrigger>,
        lastRequestedAt: Date?
    ) {
        self.startedAt = startedAt
        self.thanksCountedUntil = thanksCountedUntil
        self.thanksCountedKeysAtMarker = thanksCountedKeysAtMarker
        self.receivedThanksCount = receivedThanksCount
        self.requestedTriggers = requestedTriggers
        self.lastRequestedAt = lastRequestedAt
    }

}

/// 数えたありがとうを区別するキー。家事1件につき、送った人ごとに1件のありがとうが届く
public struct AppReviewThanksKey: Hashable, Sendable, Codable {

    public let houseworkId: String
    public let senderId: String

    public init(houseworkId: String, senderId: String) {
        self.houseworkId = houseworkId
        self.senderId = senderId
    }

}
