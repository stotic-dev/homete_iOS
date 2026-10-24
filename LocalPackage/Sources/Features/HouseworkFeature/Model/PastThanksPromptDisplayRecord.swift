//
//  PastThanksPromptDisplayRecord.swift
//  LocalPackage
//

import Foundation

/// ホームのカードに、過去の促しを出した記録
///
/// 過去の家事へのありがとうは急ぐものではないので、何度も出して急かさないよう1日に`maxShownCount`回までにする。
/// 数え方は届いたありがとう（`ReceivedThanksDisplayRecord`）と同じで、端末に保存し、日付が変わったら数え直す。
/// 読み出した値は`reconciled(now:calendar:)`で今日の状況に合わせてから使う。
public struct PastThanksPromptDisplayRecord: Equatable, Sendable {

    /// 1日に出す回数の上限
    public static let maxShownCount = 2

    /// 記録した日（その日の0時）。まだ記録していなければ`nil`
    public private(set) var day: Date?
    /// その日に出した回数
    public private(set) var shownCount: Int

    public init(day: Date? = nil, shownCount: Int = 0) {
        self.day = day
        self.shownCount = shownCount
    }

}

public extension PastThanksPromptDisplayRecord {

    /// 今日の状況に合わせた記録。日付が変わっていたら、回数を戻す
    func reconciled(now: Date, calendar: Calendar) -> Self {
        let today = calendar.startOfDay(for: now)
        guard day == today else { return .init(day: today) }

        return self
    }

    /// カードに出してよいか
    ///
    /// - Parameter isCountedInCurrentAppearance: 今のホームの表示で、すでに出した回として数えたか。
    ///   表示中に上限に達しても、その場では消さない
    func canShow(isCountedInCurrentAppearance: Bool) -> Bool {
        isCountedInCurrentAppearance || shownCount < Self.maxShownCount
    }

    /// カードに出したことを記録する
    mutating func recordShown() {
        shownCount += 1
    }

}

/// RawRepresentableにも準拠させるため、既定の実装（rawValueを読み書きする）に任せず、プロパティを直接読み書きする
extension PastThanksPromptDisplayRecord: Codable {

    enum CodingKeys: String, CodingKey {

        case day
        case shownCount

    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(day, forKey: .day)
        try container.encode(shownCount, forKey: .shownCount)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decodeIfPresent(Date.self, forKey: .day)
        shownCount = try container.decode(Int.self, forKey: .shownCount)
    }

}

extension PastThanksPromptDisplayRecord: RawRepresentable {

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
