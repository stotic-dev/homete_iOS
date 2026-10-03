//
//  HouseworkMemoLimitPolicy.swift
//  LocalPackage
//

/// プランごとの家事メモの文字数・項目数の上限
/// - Note: 判定には操作している本人のプランを使う。上限はクライアントでだけ判定し、
///         Firestoreのセキュリティルールではプランに依存しない安全上限だけを検査する（ADR-0034）
public enum HouseworkMemoLimitPolicy: Equatable, Sendable {

    /// 無料プラン
    case free
    /// プレミアムプラン
    case premium

    /// 無料プランで書ける文字数
    public static let freeMaxCharacterCount = 200
    /// プレミアムプランで書ける文字数。実質上限なしだが、Firestoreの1ドキュメント1MiBの制限を守るために設ける
    public static let premiumMaxCharacterCount = 5000
    /// チェックリストの項目数の上限（プラン共通）
    public static let maxChecklistItemCount = 100

    public init(isPremium: Bool) {
        self = isPremium ? .premium : .free
    }

    /// 書ける文字数（テキストとチェックリストの項目名の合計）
    public var maxCharacterCount: Int {
        switch self {
        case .free:
            Self.freeMaxCharacterCount

        case .premium:
            Self.premiumMaxCharacterCount
        }
    }

    /// 編集したメモを保存できるか
    ///
    /// 上限を超えていても、編集前より文字数・項目数が増えていなければ保存できる。
    /// プレミアムプランの同居人が書いたメモや、無料プランに戻る前に書いたメモでも、
    /// チェックを付けたり文字を減らしたりはできるようにするため。
    /// - Parameter original: 編集前のメモ。新しく書く場合は`nil`
    public func canSave(_ memo: HouseworkMemo, original: HouseworkMemo?) -> Bool {
        let originalCharacterCount = original?.characterCount ?? 0
        let originalItemCount = original?.checklist.count ?? 0
        let isCharacterCountValid = memo.characterCount <= maxCharacterCount
            || memo.characterCount <= originalCharacterCount
        let isItemCountValid = memo.checklist.count <= Self.maxChecklistItemCount
            || memo.checklist.count <= originalItemCount
        return isCharacterCountValid && isItemCountValid
    }

    /// 保存するメモが上限を超えていないか検査する
    /// - Parameters:
    ///   - memo: 保存するメモ。メモを持たない場合は`nil`（検査しない）
    ///   - original: 編集前のメモ。新しく書く場合は`nil`
    /// - Throws: 上限を超えている場合は`HouseworkMemoError.limitExceeded`
    public func validate(_ memo: HouseworkMemo?, original: HouseworkMemo?) throws {
        guard let memo, !canSave(memo, original: original) else { return }
        throw HouseworkMemoError.limitExceeded
    }

}
