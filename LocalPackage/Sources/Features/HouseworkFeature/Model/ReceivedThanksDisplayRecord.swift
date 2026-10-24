//
//  ReceivedThanksDisplayRecord.swift
//  LocalPackage
//

import Foundation

/// ホームのカードに、届いたありがとうを出した記録
///
/// 一度見ただけで消えないよう、1日に`maxShownCount`回まで出す。×で隠したらその日は出さない。
/// 端末に保存し、日付が変わったら数え直す。
/// 読み出した値は`reconciled(with:now:calendar:)`で今日の状況に合わせてから使う。
public struct ReceivedThanksDisplayRecord: Equatable, Sendable {

    /// 1日に出す回数の上限
    public static let maxShownCount = 3

    /// 記録した日（その日の0時）。まだ記録していなければ`nil`
    public private(set) var day: Date?
    /// その日に出した回数
    public private(set) var shownCount: Int
    /// ×で隠したときに数えていた、最後に届いたありがとうの日時。隠していなければ`nil`
    public private(set) var dismissedLatestSentAt: Date?

    public init(day: Date? = nil, shownCount: Int = 0, dismissedLatestSentAt: Date? = nil) {
        self.day = day
        self.shownCount = shownCount
        self.dismissedLatestSentAt = dismissedLatestSentAt
    }

}

public extension ReceivedThanksDisplayRecord {

    /// 今日の状況に合わせた記録
    ///
    /// 日付が変わっていたら、回数と×の状態を戻す。
    /// ×で隠した後に新しいありがとうが届いていたら、また出せるよう回数も0に戻す。
    func reconciled(with receivedThanks: ReceivedThanksSummary, now: Date, calendar: Calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        guard day == today else { return .init(day: today) }

        if let dismissedLatestSentAt,
           let latestSentAt = receivedThanks.latestSentAt,
           latestSentAt > dismissedLatestSentAt {
            return .init(day: today)
        }
        return self
    }

    /// カードに出してよいか
    ///
    /// - Parameter isCountedInCurrentAppearance: 今のホームの表示で、すでに出した回として数えたか。
    ///   表示中に上限に達しても、その場では消さない
    func canShow(_ receivedThanks: ReceivedThanksSummary, isCountedInCurrentAppearance: Bool) -> Bool {
        guard receivedThanks.hasReceived, dismissedLatestSentAt == nil else { return false }

        return isCountedInCurrentAppearance || shownCount < Self.maxShownCount
    }

    /// カードに出したことを記録する
    mutating func recordShown() {
        shownCount += 1
    }

    /// ×で隠したことを記録する
    mutating func dismiss(_ receivedThanks: ReceivedThanksSummary) {
        dismissedLatestSentAt = receivedThanks.latestSentAt ?? .distantPast
    }

}

/// RawRepresentableにも準拠させるため、既定の実装（rawValueを読み書きする）に任せず、プロパティを直接読み書きする
extension ReceivedThanksDisplayRecord: Codable {

    enum CodingKeys: String, CodingKey {

        case day
        case shownCount
        case dismissedLatestSentAt

    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(day, forKey: .day)
        try container.encode(shownCount, forKey: .shownCount)
        try container.encodeIfPresent(dismissedLatestSentAt, forKey: .dismissedLatestSentAt)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(Date.self, forKey: .day)
        shownCount = try container.decode(Int.self, forKey: .shownCount)
        dismissedLatestSentAt = try container.decodeIfPresent(Date.self, forKey: .dismissedLatestSentAt)
    }

}

extension ReceivedThanksDisplayRecord: RawRepresentable {

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        self = decoded
    }

    /// RawRepresentableどうしの`==`はこの値で比べられることがあるため、キーの順を固定して同じ記録なら同じ文字列にする
    public var rawValue: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return jsonString
    }

}
