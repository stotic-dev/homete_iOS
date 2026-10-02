//
//  RegisterHouseworkDraft.swift
//  LocalPackage
//

import HometeDomain

/// 家事の登録シートで入力中の内容
/// - Note: 「いつもの家事から選んだもの」「続けて入力で積んだもの」「入力中のもの」をまとめて登録予定リストにする
struct RegisterHouseworkDraft: Equatable {

    /// 選んだいつもの家事のID（選んだ順を保つ）
    var selectedFrequentItemIds: [String]
    /// 「続けて入力する」で積んだ家事
    var queuedEntries: [ManualEntry]
    /// 「新しく入力」タブで入力中の家事
    var input: ManualEntry

    init(
        selectedFrequentItemIds: [String] = [],
        queuedEntries: [ManualEntry] = [],
        input: ManualEntry = .initial
    ) {
        self.selectedFrequentItemIds = selectedFrequentItemIds
        self.queuedEntries = queuedEntries
        self.input = input
    }

}

extension RegisterHouseworkDraft {

    /// 「新しく入力」タブの1件分
    struct ManualEntry: Equatable, Identifiable {

        /// 登録予定リストで1件を指すためのID。入力中のものは空文字にしておき、積むときに採番する
        var id: String
        var title: String
        var point: Int
        /// 「いつもの家事に保存する」をオンにしたときに使うカテゴリ
        var categoryId: String?
        var savesAsFrequent: Bool
        var recurrenceInput: HouseworkRecurrenceInput
        /// 家事に付けるメモ。書いていなければ`nil`
        var memo: HouseworkMemo?

        /// 「新しく入力」タブの初期値（家事登録シートと同じく10ポイント）
        static let initial = ManualEntry(
            id: "",
            title: "",
            point: 10,
            categoryId: nil,
            savesAsFrequent: false,
            recurrenceInput: .init(kind: .none)
        )

    }

}

// MARK: - 登録予定リスト

extension RegisterHouseworkDraft {

    /// 登録予定リスト（選択中のいつもの家事 → 続けて入力 → 入力中の順）
    /// - Note: 入力中のものは、名前が空でなければ含める
    func pendingEntries(context: FrequentHouseworkContext) -> [PendingEntry] {
        let frequentEntries = selectedFrequentItemIds.compactMap { itemId -> PendingEntry? in
            guard let item = context.items.first(where: { $0.id == itemId }) else { return nil }
            return .init(
                source: .frequent(itemId: item.id),
                title: item.title,
                point: item.point,
                recurrence: nil,
                savesAsFrequent: false,
                categoryId: item.categoryId,
                memo: item.memo
            )
        }
        let queued = queuedEntries.map { PendingEntry(queued: $0) }
        let editing = Self.isBlank(input.title) ? [] : [PendingEntry(editing: input)]
        return frequentEntries + queued + editing
    }

    /// キャンセル時に破棄の確認が要るか
    var hasInput: Bool {
        !selectedFrequentItemIds.isEmpty || !queuedEntries.isEmpty || !Self.isBlank(input.title)
    }

    /// 「続けて入力する」を押せるか
    var canQueueCurrentInput: Bool {
        !Self.isBlank(input.title) && input.recurrenceInput.isValid
    }

}

// MARK: - 入力の更新

extension RegisterHouseworkDraft {

    /// いつもの家事の選択を切り替える
    mutating func toggleFrequentItem(_ itemId: String) {
        if let index = selectedFrequentItemIds.firstIndex(of: itemId) {
            selectedFrequentItemIds.remove(at: index)
        } else {
            selectedFrequentItemIds.append(itemId)
        }
    }

    /// 入力中の内容を登録予定リストに積み、フォームを初期値に戻す
    /// - Parameter id: 積む1件に振るID
    mutating func queueCurrentInput(id: String) {
        guard canQueueCurrentInput else { return }
        var queued = input
        queued.id = id
        queued.title = FrequentHouseworkContext.normalize(input.title)
        queuedEntries.append(queued)
        input = .initial
    }

    /// 登録予定リストから1件取り消す
    mutating func remove(_ entry: PendingEntry) {
        switch entry.source {
        case let .frequent(itemId):
            selectedFrequentItemIds.removeAll { $0 == itemId }

        case let .queued(entryId):
            queuedEntries.removeAll { $0.id == entryId }

        case .editing:
            input = .initial
        }
    }

}

// MARK: - 「いつもの家事に保存する」

extension RegisterHouseworkDraft {

    /// 「いつもの家事に保存する」チェックの状態
    enum SaveAsFrequentState: Equatable {

        /// 操作できる
        case available
        /// 同じ名前のいつもの家事がすでにある
        case duplicated
        /// 無料プランの上限に達している
        case limitReached

        var isAvailable: Bool {
            self == .available
        }

    }

    /// 入力中の家事を「いつもの家事に保存する」にできるか
    /// - Note: 名前が空のうちは判定できないため、操作できる扱いにしておく（決定は名前を入れてから）
    func saveAsFrequentState(
        context: FrequentHouseworkContext,
        limitPolicy: FrequentHouseworkLimitPolicy
    ) -> SaveAsFrequentState {
        if limitPolicy.isLimitReached(currentCount: context.items.count) {
            return .limitReached
        }
        if !Self.isBlank(input.title), context.containsTitle(input.title) {
            return .duplicated
        }
        return .available
    }

}

private extension RegisterHouseworkDraft {

    static func isBlank(_ value: String) -> Bool {
        FrequentHouseworkContext.normalize(value).isEmpty
    }

}
