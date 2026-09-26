//
//  FrequentHouseworkStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// 同居人グループのいつもの家事を購読し、追加・編集・削除を行う
/// - Note: 同時編集は後勝ちとし、ロックは設けない。
///         名前の重複・件数の上限はクライアント側でのみ判定する（同居人が同時に追加すると一時的に超えることがある）
@MainActor
@Observable
public final class FrequentHouseworkStore {

    /// 購読しているいつもの家事とカスタムカテゴリ
    /// - Note: 2つのリスナーの結果を1つの値にまとめて持つ。
    ///         別々に持つと、件数上限・名前の重複・並び順を片方だけ見て判定する経路ができてしまう
    public private(set) var context: FrequentHouseworkContext
    /// いつもの家事とカスタムカテゴリの初回受信の状態
    /// - Note: 両方の最初のスナップショットが揃うまでは`loading`のまま。
    ///         揃う前は件数上限・名前の重複・カテゴリの判定が正しくできないため、画面は追加や編集をさせない
    public private(set) var loadState: ListenerLoadState

    private var itemsObserveTask: Task<Void, Never>?
    private var categoriesObserveTask: Task<Void, Never>?
    private var hasReceivedItems = false
    private var hasReceivedCategories = false
    /// 購読の開始・解除を直列に実行するための、最後に積んだ処理
    private var listenerLifecycleTask: Task<Void, Never>?

    private let frequentHouseworkClient: FrequentHouseworkClient
    private let analyticsClient: AnalyticsClient
    private let now: @Sendable () -> Date
    private let idGenerator: @Sendable () -> String
    private let itemsListenerKey = "frequentHouseworksListener"
    private let categoriesListenerKey = "frequentHouseworkCategoriesListener"

    public init(
        frequentHouseworkClient: FrequentHouseworkClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        context: FrequentHouseworkContext = .init(),
        loadState: ListenerLoadState = .loading,
        now: @escaping @Sendable () -> Date = { .now },
        idGenerator: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.frequentHouseworkClient = frequentHouseworkClient
        self.analyticsClient = analyticsClient
        self.context = context
        self.loadState = loadState
        self.now = now
        self.idGenerator = idGenerator
    }

}

// MARK: - 購読

public extension FrequentHouseworkStore {

    /// いつもの家事とカスタムカテゴリの購読を開始する
    /// - Note: すでに購読中の場合は解除してから開始する（グループの切り替え・再試行に備える）
    func startObserving(cohabitantId: String) async {
        await enqueueListenerLifecycle {
            await self.performStartObserving(cohabitantId: cohabitantId)
        }
    }

    /// いつもの家事とカスタムカテゴリの購読を解除する
    func stopObserving() async {
        await enqueueListenerLifecycle {
            await self.performStopObserving()
        }
    }

}

private extension FrequentHouseworkStore {

    /// 購読の開始・解除を1本の列に並べ、前の処理が終わってから次を始める
    /// - Note: 開始・解除は途中で`await`を挟むため、並行して呼ばれると解除と登録が入り組み、
    ///         同じIDで二重に登録されたリスナーが解除されないまま残る（再試行の連打・グループ切り替えで起こる）
    func enqueueListenerLifecycle(_ operation: @escaping @MainActor @Sendable () async -> Void) async {
        let previousTask = listenerLifecycleTask
        let task = Task { @MainActor in
            await previousTask?.value
            await operation()
        }
        listenerLifecycleTask = task
        await task.value
    }

    func performStartObserving(cohabitantId: String) async {
        await performStopObserving()
        loadState = .loading
        hasReceivedItems = false
        hasReceivedCategories = false

        let itemsStream = await frequentHouseworkClient.addItemsSnapshotListener(itemsListenerKey, cohabitantId)
        let categoriesStream = await frequentHouseworkClient.addCategoriesSnapshotListener(
            categoriesListenerKey,
            cohabitantId
        )
        itemsObserveTask = Task {
            for await items in itemsStream {
                self.context = self.context.replacingItems(items)
                self.hasReceivedItems = true
                self.markLoadedIfReady()
            }
            self.markFailedIfListenerEnded()
        }
        categoriesObserveTask = Task {
            for await categories in categoriesStream {
                self.context = self.context.replacingCustomCategories(categories)
                self.hasReceivedCategories = true
                self.markLoadedIfReady()
            }
            self.markFailedIfListenerEnded()
        }
    }

    func performStopObserving() async {
        itemsObserveTask?.cancel()
        itemsObserveTask = nil
        categoriesObserveTask?.cancel()
        categoriesObserveTask = nil
        await frequentHouseworkClient.removeListener(itemsListenerKey)
        await frequentHouseworkClient.removeListener(categoriesListenerKey)
    }

}

private extension FrequentHouseworkStore {

    /// 両方の最初のスナップショットが揃ったら読み込み済みにする
    /// - Note: 片方のリスナーが先に終わって失敗になっている場合は、もう片方が届いても失敗のままにする
    ///         （止まったリスナーの古いデータで件数上限・名前の重複を判定させないため）
    func markLoadedIfReady() {
        guard loadState == .loading, hasReceivedItems, hasReceivedCategories else { return }
        loadState = .loaded
    }

    /// リスナーが終わった場合は、読み込み前・後を問わず失敗とみなす
    /// - Note: 終わったリスナーのデータは以降更新されないため、読み込み済みのままにすると
    ///         古いデータで件数上限・名前の重複を判定してしまう。購読の解除（タスクのキャンセル）で終わった場合は対象外。
    ///         リスナーのエラーはClientでログ出力のうえストリームの終了に変換されるため、終了したことで検知する
    func markFailedIfListenerEnded() {
        guard !Task.isCancelled else { return }
        loadState = .failed(.other)
    }

}

// MARK: - いつもの家事

public extension FrequentHouseworkStore {

    /// いつもの家事を追加する
    /// - Note: 各カテゴリの末尾に、入力の順で追加する
    /// - Throws: 名前が空・重複（入力同士の重複を含む）の場合、上限を超える場合は`FrequentHouseworkError`
    func add(
        _ inputs: [FrequentHouseworkInput],
        limitPolicy: FrequentHouseworkLimitPolicy,
        step: FrequentHouseworkAnalyticsStep,
        cohabitantId: String
    ) async throws {
        let newItems = try context.makeAddedItems(
            from: inputs,
            limitPolicy: limitPolicy,
            timestamp: now(),
            idGenerator: idGenerator
        )
        do {
            try await frequentHouseworkClient.upsertItems(newItems, cohabitantId)
        } catch {
            newItems.forEach { _ in analyticsClient.log(.frequentHousework(.create(step: step, isSuccess: false))) }
            throw error
        }
        newItems.forEach { _ in analyticsClient.log(.frequentHousework(.create(step: step, isSuccess: true))) }
    }

    /// テンプレートの家事を取り込む
    /// - Note: カテゴリは未設定で追加する。登録済みの候補は取り込まない
    /// - Throws: 上限を超える場合は`FrequentHouseworkError.limitExceeded`
    func importFromTemplate(
        _ candidates: [FrequentHouseworkImportCandidate],
        limitPolicy: FrequentHouseworkLimitPolicy,
        cohabitantId: String
    ) async throws {
        let inputs = candidates
            .filter { !$0.isAlreadyRegistered }
            .map { FrequentHouseworkInput(title: $0.title, point: $0.point, categoryId: nil) }
        let newItems = try context.makeAddedItems(
            from: inputs,
            limitPolicy: limitPolicy,
            timestamp: now(),
            idGenerator: idGenerator
        )
        do {
            try await frequentHouseworkClient.upsertItems(newItems, cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.importFromTemplate(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.importFromTemplate(isSuccess: true)))
    }

    /// いつもの家事を編集する
    /// - Note: カテゴリを変えた場合は、移動先のカテゴリの末尾に並べる。
    ///         編集中に同居人が削除していた場合は、復活させないよう何もしない
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func update(
        itemId: String,
        input: FrequentHouseworkInput,
        cohabitantId: String
    ) async throws {
        guard let updatedItem = try context.makeUpdatedItem(
            itemId: itemId,
            input: input,
            timestamp: now()
        ) else { return }
        do {
            try await frequentHouseworkClient.upsertItems([updatedItem], cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.edit(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.edit(isSuccess: true)))
    }

    /// いつもの家事を削除する
    func delete(itemId: String, cohabitantId: String) async throws {
        do {
            try await frequentHouseworkClient.deleteItem(itemId, cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.delete(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.delete(isSuccess: true)))
    }

    /// カテゴリ内の家事を並べ替える
    /// - Parameter orderedIds: 並べ替え後の順に並べた、1つのカテゴリの家事ID
    /// - Note: 並び順が変わった家事だけを書き込む
    func reorderItems(_ orderedIds: [String], cohabitantId: String) async throws {
        let reorderedItems = context.makeReorderedItems(orderedIds: orderedIds)
        guard !reorderedItems.isEmpty else { return }
        try await frequentHouseworkClient.upsertItems(reorderedItems, cohabitantId)
    }

    /// 無料プランの上限の案内を表示したことを記録する
    func logLimitReached(step: FrequentHouseworkAnalyticsStep) {
        analyticsClient.log(.frequentHousework(.limitReached(step: step)))
    }

}

// MARK: - カスタムカテゴリ

public extension FrequentHouseworkStore {

    /// カスタムカテゴリを追加する
    /// - Returns: 追加したカテゴリ（追加と同時に選択状態にするため）
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    @discardableResult
    func addCategory(name: String, cohabitantId: String) async throws -> FrequentHouseworkCustomCategory {
        let newCategory = try context.makeAddedCategory(name: name, id: idGenerator(), createdAt: now())
        do {
            try await frequentHouseworkClient.upsertCategories([newCategory], cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.createCategory(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.createCategory(isSuccess: true)))
        return newCategory
    }

    /// カスタムカテゴリの名前を変更する
    /// - Throws: 名前が空・重複の場合は`FrequentHouseworkError`
    func renameCategory(id: String, name: String, cohabitantId: String) async throws {
        guard let renamedCategory = try context.makeRenamedCategory(id: id, name: name) else { return }
        do {
            try await frequentHouseworkClient.upsertCategories([renamedCategory], cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.editCategory(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.editCategory(isSuccess: true)))
    }

    /// カスタムカテゴリを削除する
    /// - Note: カテゴリを指している家事は書き換えず、表示時に「その他」として扱う
    func deleteCategory(id: String, cohabitantId: String) async throws {
        do {
            try await frequentHouseworkClient.deleteCategory(id, cohabitantId)
        } catch {
            analyticsClient.log(.frequentHousework(.deleteCategory(isSuccess: false)))
            throw error
        }
        analyticsClient.log(.frequentHousework(.deleteCategory(isSuccess: true)))
    }

    /// カスタムカテゴリを並べ替える
    /// - Parameter orderedIds: 並べ替え後の順に並べたカスタムカテゴリのID
    /// - Note: 並び順が変わったカテゴリだけを書き込む
    func reorderCategories(_ orderedIds: [String], cohabitantId: String) async throws {
        let reorderedCategories = context.makeReorderedCategories(orderedIds: orderedIds)
        guard !reorderedCategories.isEmpty else { return }
        try await frequentHouseworkClient.upsertCategories(reorderedCategories, cohabitantId)
    }

}
