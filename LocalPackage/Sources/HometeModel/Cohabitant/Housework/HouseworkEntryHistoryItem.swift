//
//  HouseworkEntryHistoryItem.swift
//  LocalPackage
//

/// 家事の登録シートの「新しく入力」で登録した内容の履歴1件
/// - Note: 同じ名前の家事を何度も入力し直さずに済むよう、名前と完了ポイントをまとめて覚えておく
public struct HouseworkEntryHistoryItem: Identifiable, Equatable, Hashable, Sendable {

    /// 家事の名前。履歴の同一性はこれで判断する
    public var id: String {
        title
    }

    public let title: String
    /// 最後に登録したときの完了ポイント
    public let point: Int

    public init(title: String, point: Int) {
        self.title = title
        self.point = point
    }

}
