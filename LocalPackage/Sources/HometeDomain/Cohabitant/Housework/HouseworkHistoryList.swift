//
//  HouseworkHistoryList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

/// 家事の入力履歴（新しく使ったものが先頭）
/// - Note: 並び順はこの値型が持ち、永続化層（SQLite）は並び順を含めて保存するだけにしている。
///         こうしておくと「使ったものを先頭に出す」判断をDBを介さずユニットテストできる
public struct HouseworkHistoryList: Equatable, Sendable {

    public private(set) var items: [HouseworkEntryHistoryItem]

    public init(items: [HouseworkEntryHistoryItem]) {
        self.items = items
    }

    /// 履歴があるかどうか
    public var hasHistory: Bool {
        !items.isEmpty
    }

    /// 引数に受け取った名前の履歴が存在する場合、その要素を先頭へ移動します。
    /// - Parameter title: 先頭へ移動したい履歴の家事名
    public mutating func moveToFrontIfExists(_ title: String) {
        guard let index = items.firstIndex(where: { $0.title == title }) else { return }
        // 既に先頭なら何もしない
        if index == items.startIndex { return }
        let element = items.remove(at: index)
        items.insert(element, at: 0)
    }

    /// 引数に受け取った履歴を `items` の先頭に追加する
    /// - Parameter item: 新しい履歴
    /// - Note: 同じ名前の履歴があれば、完了ポイントを新しいもので置き換えて先頭へ移す。
    ///         前回と違うポイントで登録し直したときに、次の復元で古いポイントが出ないようにするため
    public mutating func addNewHistory(_ item: HouseworkEntryHistoryItem) {
        items.removeAll { $0.title == item.title }
        items.insert(item, at: 0)
    }

}
