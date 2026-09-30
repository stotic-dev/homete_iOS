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

    public private(set) var items: [String]

    public init(items: [String]) {
        self.items = items
    }

    /// 履歴があるかどうか
    public var hasHistory: Bool {
        !items.isEmpty
    }

    /// 引数に受け取った文字列が `items` に存在する場合、その要素を先頭へ移動します。
    /// - Parameter value: 先頭へ移動したい要素の文字列
    public mutating func moveToFrontIfExists(_ value: String) {
        guard let index = items.firstIndex(of: value) else { return }
        // 既に先頭なら何もしない
        if index == items.startIndex { return }
        let element = items.remove(at: index)
        items.insert(element, at: 0)
    }

    /// 引数に受け取った文字列を `items`の先頭に追加する
    /// - Parameter value: 新しい履歴文字
    public mutating func addNewHistory(_ value: String) {
        guard items.contains(value) else {
            items.insert(value, at: 0)
            return
        }
        moveToFrontIfExists(value)
    }

}
