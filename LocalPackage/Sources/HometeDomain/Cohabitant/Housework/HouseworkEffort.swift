//
//  HouseworkEffort.swift
//  LocalPackage
//

/// 家事を完了にしたときの頑張り度
///
/// 家事のポイント（上乗せ前）とは別のフィールドで保存し、上乗せ後のポイントは都度計算する（ADR-0024）。
public enum HouseworkEffort: String, CaseIterable, Codable, Identifiable, Sendable {

    /// ふつう
    case normal
    /// がんばった
    case hard
    /// 超頑張った
    case veryHard

    public var id: Self {
        self
    }

    /// 家事のポイントに掛ける割合（%）
    public var ratePercentage: Int {
        switch self {
        case .normal:
            100

        case .hard:
            120

        case .veryHard:
            150
        }
    }

    /// 頑張り度で上乗せした後のポイント
    ///
    /// ポイントが小さい家事でも頑張った分が必ず増えるよう、端数は切り上げる。
    /// 浮動小数点の誤差で切り上げ結果がずれないよう、整数演算で計算する。
    public func boostedPoint(_ point: Int) -> Int {
        (point * ratePercentage + 99) / 100
    }

}
