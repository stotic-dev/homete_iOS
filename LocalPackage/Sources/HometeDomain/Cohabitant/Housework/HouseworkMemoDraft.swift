//
//  HouseworkMemoDraft.swift
//  LocalPackage
//

import Foundation

/// 編集中の家事メモ
public struct HouseworkMemoDraft: Equatable, Sendable {

    /// 編集中のチェックリストの項目
    public struct Item: Identifiable, Equatable, Sendable {

        public let id: String
        public var title: String
        public let isChecked: Bool

        public init(id: String, title: String, isChecked: Bool) {
            self.id = id
            self.title = title
            self.isChecked = isChecked
        }

    }

    public var text: String
    public private(set) var checklist: [Item]
    /// 編集前のメモ。新しく書く場合は`nil`
    public let original: HouseworkMemo?

    public init(original: HouseworkMemo?) {
        self.original = original
        text = original?.text ?? ""
        checklist = original?.checklist.map { .init(id: $0.id, title: $0.title, isChecked: $0.isChecked) } ?? []
    }

    /// 保存するメモ
    ///
    /// テキストと項目名の前後の空白・改行を除き、項目名が空の項目は除く。
    public var memo: HouseworkMemo {
        .init(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            checklist: checklist.compactMap { item in
                let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return nil }
                return .init(id: item.id, title: title, isChecked: item.isChecked)
            }
        )
    }

    /// 編集前から変わっているか
    public var hasChanges: Bool {
        memo != (original ?? .empty)
    }

    /// チェックリストの項目を追加できるか
    public var canAddItem: Bool {
        checklist.count < HouseworkMemoLimitPolicy.maxChecklistItemCount
    }

    /// 末尾に空の項目を追加する
    public mutating func addItem(id: String) {
        guard canAddItem else { return }
        checklist.append(.init(id: id, title: "", isChecked: false))
    }

    /// 項目名を変える
    public mutating func updateTitle(_ title: String, of id: Item.ID) {
        guard let index = checklist.firstIndex(where: { $0.id == id }) else { return }
        checklist[index].title = title
    }

    /// 項目を削除する
    public mutating func removeItem(id: Item.ID) {
        checklist.removeAll { $0.id == id }
    }

    /// 上限を超えていて保存できないか
    public func isOverLimit(_ policy: HouseworkMemoLimitPolicy) -> Bool {
        !policy.canSave(memo, original: original)
    }

    /// 保存できるか
    public func canSave(_ policy: HouseworkMemoLimitPolicy) -> Bool {
        hasChanges && !isOverLimit(policy)
    }

}
