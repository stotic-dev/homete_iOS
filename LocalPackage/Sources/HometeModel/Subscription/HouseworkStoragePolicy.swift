//
//  HouseworkStoragePolicy.swift
//  LocalPackage
//

import Foundation

/// プランごとの家事データの保存期間ポリシー
///
/// 閲覧可能な範囲・起動時のフェッチ範囲の算出をこの型に集約する。期間の定義を変更する場合はここだけを直せばよい。
/// - Note: Firestore上の保持期限(`expiredAt`)はCloud Functionsが決める（homete_backendのADR-0065）。
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

    /// プレミアムプランの起動時フェッチ期間（月数）
    static var premiumInitialFetchMonths: Int {
        12
    }

}
