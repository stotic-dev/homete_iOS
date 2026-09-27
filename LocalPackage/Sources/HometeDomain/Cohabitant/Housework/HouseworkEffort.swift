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

    /// 未知の値を「ふつう」として扱うデコード
    ///
    /// 将来段階を増やしたり名前を変えたりしたとき、素のCodable準拠では知らない値の家事が1件あるだけで
    /// 家事リスト全体のデコードが失敗する。今のアプリでも読めるよう、知らない値は上乗せしない「ふつう」に寄せる。
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: rawValue) ?? .normal
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
