//
//  HouseworkMemo.swift
//  LocalPackage
//

/// 家事に付けるメモ。自由記述のテキストとチェックリストを持つ
public struct HouseworkMemo: Codable, Sendable, Equatable, Hashable {

    /// 自由記述のテキスト
    public let text: String
    /// チェックリスト
    public let checklist: [HouseworkMemoChecklistItem]

    /// 書いたメモをすべて消したもの
    /// - Note: 旧バージョンのアプリによる上書きを防ぐため、一度メモを書いた家事は消しても`memo`を残す（ADR-0034）
    public static let empty = HouseworkMemo(text: "", checklist: [])

    public init(text: String, checklist: [HouseworkMemoChecklistItem]) {
        self.text = text
        self.checklist = checklist
    }

    /// 文字数上限の判定に使う文字数。テキストとチェックリストの項目名の合計
    public var characterCount: Int {
        text.count + checklist.reduce(0) { $0 + $1.title.count }
    }

    /// テキストもチェックリストも空か
    public var isEmpty: Bool {
        text.isEmpty && checklist.isEmpty
    }

    /// 指定した項目のチェックを切り替えたメモを返す
    public func toggled(_ itemId: HouseworkMemoChecklistItem.ID) -> Self {
        .init(
            text: text,
            checklist: checklist.map { $0.id == itemId ? $0.toggled() : $0 }
        )
    }

    /// 同じ項目のチェック状態を`latest`に合わせたメモを返す
    ///
    /// 編集シートではチェックを変えられないため、シートを開いている間に同居人が付けたチェックを、
    /// 保存で開いた時点の状態に戻さないようにする。`latest`に無い項目（追加した項目）はそのまま。
    public func mergingCheckState(from latest: HouseworkMemo?) -> Self {
        guard let latest else { return self }
        let latestCheckStates = Dictionary(
            latest.checklist.map { ($0.id, $0.isChecked) },
            uniquingKeysWith: { first, _ in first }
        )
        return .init(
            text: text,
            checklist: checklist.map { item in
                guard let isChecked = latestCheckStates[item.id] else { return item }
                return .init(id: item.id, title: item.title, isChecked: isChecked)
            }
        )
    }

}

/// メモのチェックリストの項目
public struct HouseworkMemoChecklistItem: Identifiable, Codable, Sendable, Equatable, Hashable {

    public let id: String
    /// 項目名
    public let title: String
    /// チェック済みか
    public let isChecked: Bool

    public init(id: String, title: String, isChecked: Bool) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
    }

    func toggled() -> Self {
        .init(id: id, title: title, isChecked: !isChecked)
    }

}

public extension HouseworkMemo? {

    /// 表示する内容があるか。一度も書いていない（`nil`）か、書いたメモを消した（空）なら`false`
    var hasContent: Bool {
        guard let self else { return false }
        return !self.isEmpty
    }

}
