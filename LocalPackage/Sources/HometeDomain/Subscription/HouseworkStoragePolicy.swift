//
//  HouseworkStoragePolicy.swift
//  LocalPackage
//

import Foundation

/// プランごとの家事データの保存期間ポリシー
///
/// 閲覧可能な範囲・起動時のフェッチ範囲・Firestore上の保持期限(`expiredAt`)の
/// 算出をこの型に集約する。期間の定義を変更する場合はここだけを直せばよい。
public enum HouseworkStoragePolicy: Equatable, Sendable {

    /// 無料プラン
    case free
    /// プレミアムプラン
    case premium

    public init(isPremium: Bool) {
        self = isPremium ? .premium : .free
    }

}

// MARK: 閲覧範囲

public extension HouseworkStoragePolicy {

    /// 閲覧可能な最古の日付
    /// - Returns: プレミアムは無制限のため`nil`を返す
    func viewableLowerBound(currentDate: Date, calendar: Calendar) -> Date? {
        switch self {
        case .free:
            let today = calendar.startOfDay(for: currentDate)
            return calendar.date(byAdding: .month, value: -Self.freeViewableMonths, to: today)

        case .premium:
            return nil
        }
    }

    /// 指定した日付が閲覧可能な範囲内か
    func isViewable(_ date: Date, currentDate: Date, calendar: Calendar) -> Bool {
        guard let lowerBound = viewableLowerBound(currentDate: currentDate, calendar: calendar) else { return true }

        return calendar.startOfDay(for: date) >= lowerBound
    }

    /// 家事ボードで過去方向に遡れる日数
    /// - Returns: プレミアムは無制限のため`nil`を返す
    var boardBackwardDays: Int? {
        switch self {
        case .free: Self.freeBoardBackwardDays
        case .premium: nil
        }
    }

}

// MARK: フェッチ範囲

public extension HouseworkStoragePolicy {

    /// 起動時にワンショットで取得する期間の開始日
    ///
    /// プレミアムは閲覧範囲こそ無制限だが、全期間の一括取得は起動時間に影響するため
    /// 初回は直近1年に留め、それ以前は遡られた時点で追加取得する。
    func initialFetchLowerBound(currentDate: Date, calendar: Calendar) -> Date {
        let today = calendar.startOfDay(for: currentDate)
        let months = switch self {
        case .free: Self.freeViewableMonths
        case .premium: Self.premiumInitialFetchMonths
        }
        return calendar.date(byAdding: .month, value: -months, to: today) ?? today
    }

}

// MARK: 保持期限

public extension HouseworkStoragePolicy {

    /// Firestore上の保持期限(`expiredAt`)を算出する
    /// - Parameter baseDate: 保持期間の起点。家事の新規登録時は家事の日付、解約に伴う再計算時は解約日を渡す
    /// - Note: プレミアムはTTLによる自動削除が実質発生しない十分先の日付を返す。
    ///         `Date.distantFuture`はFirestoreのTimestampが表現できる範囲を超えるため使わない。
    func expiredAt(from baseDate: Date, calendar: Calendar) -> Date {
        let years = switch self {
        case .free: Self.freeRetentionYears
        case .premium: Self.premiumRetentionYears
        }
        return calendar.date(byAdding: .year, value: years, to: baseDate) ?? baseDate
    }

}

// MARK: constant

private extension HouseworkStoragePolicy {

    /// 無料プランで閲覧できる期間（月数）
    static var freeViewableMonths: Int {
        3
    }

    /// 無料プランの家事ボードで遡れる日数
    static var freeBoardBackwardDays: Int {
        30
    }

    /// 無料プランのFirestore上の保持年数
    static var freeRetentionYears: Int {
        1
    }

    /// プレミアムプランのFirestore上の保持年数（実質無期限）
    static var premiumRetentionYears: Int {
        100
    }

    /// プレミアムプランの起動時フェッチ期間（月数）
    static var premiumInitialFetchMonths: Int {
        12
    }

}
