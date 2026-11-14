//
//  FrequentHouseworkEditInput.swift
//  LocalPackage
//

/// いつもの家事の追加・編集モーダルで入力中の内容
public struct FrequentHouseworkEditInput: Equatable, Sendable {

    public var title: String
    public var point: Int
    /// カテゴリID。「その他（未設定）」は`nil`
    public var categoryId: String?
    /// 家事を追加するときに引き継ぐメモ。書いていなければ`nil`
    public var memo: HouseworkMemo?

    /// 新規追加時の初期値（家事登録シートと同じく10ポイント）
    public static let initial = FrequentHouseworkEditInput(title: "", point: 10, categoryId: nil)

    public init(title: String, point: Int, categoryId: String?, memo: HouseworkMemo? = nil) {
        self.title = title
        self.point = point
        self.categoryId = categoryId
        self.memo = memo
    }

    /// 編集する家事の内容から作る
    /// - Note: 削除済みのカテゴリを指している場合は「その他（未設定）」として扱う
    public init(item: FrequentHouseworkItem, context: FrequentHouseworkContext) {
        self.init(
            title: item.title,
            point: item.point,
            categoryId: context.category(of: item).categoryId,
            memo: item.memo
        )
    }

    /// 決定できるかどうか
    /// - Parameter editingId: 編集中の家事のID。自分自身とは名前の重複を判定しない
    /// - Note: 書き込み前の検証（`FrequentHouseworkStore`）と同じ判定を使う。
    ///         別々に実装すると、片方だけ直したときに決定ボタンは押せるのに書き込みが弾かれる状態になる
    public func validation(
        context: FrequentHouseworkContext,
        editingId: String?
    ) -> FrequentHouseworkContext.TitleValidation {
        context.validateTitle(title, excludingId: editingId)
    }

    public var domainInput: FrequentHouseworkInput {
        .init(title: title, point: point, categoryId: categoryId, memo: memo)
    }

}
