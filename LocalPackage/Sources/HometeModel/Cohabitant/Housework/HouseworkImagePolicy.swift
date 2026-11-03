//
//  HouseworkImagePolicy.swift
//  LocalPackage
//

/// プランごとの、家事に画像を添えられるかどうか
/// - Note: 判定には操作している本人のプランを使う。プランはクライアントでだけ判定し、
///         セキュリティルールではプランに依存しない枚数・サイズ・形式だけを検査する（ADR-0067）
public enum HouseworkImagePolicy: Equatable, Sendable {

    /// 無料プラン。画像の閲覧と、自分が追加した画像の削除だけができる
    case free
    /// プレミアムプラン
    case premium

    /// 1つの家事に添えられる画像の枚数（プラン共通）
    public static let maxImageCount = 10

    public init(isPremium: Bool) {
        self = isPremium ? .premium : .free
    }

    /// あと何枚添えられるか。無料プランでは常に0
    /// - Parameter currentCount: 家事に添えてある画像の枚数
    public func addableCount(currentCount: Int) -> Int {
        switch self {
        case .free:
            0

        case .premium:
            max(Self.maxImageCount - currentCount, 0)
        }
    }

    /// 画像を添えられるか検査する
    /// - Parameters:
    ///   - count: 新しく添える枚数
    ///   - currentCount: 家事に添えてある画像の枚数
    /// - Throws: 無料プランなら`HouseworkImageError.premiumRequired`、枚数を超えるなら`HouseworkImageError.limitExceeded`
    public func validateAdding(count: Int, currentCount: Int) throws {
        guard self == .premium else { throw HouseworkImageError.premiumRequired }
        guard count <= addableCount(currentCount: currentCount) else { throw HouseworkImageError.limitExceeded }
    }

    /// 画像を消せるか
    ///
    /// プレミアムプランなら同居人が追加した画像も消せる。プレミアムプランをやめた後も、
    /// 自分が追加した画像は消せるようにする（家事メモのダウングレード時の扱いと同じ方針）。
    /// - Parameter userId: 操作している本人のユーザーID
    public func canDelete(_ image: HouseworkImage, userId: String) -> Bool {
        self == .premium || image.uploaderId == userId
    }

}
