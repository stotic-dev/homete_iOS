//
//  HouseworkManager.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/11.
//

import Foundation

public final actor HouseworkManager {

    // MARK: state

    public private(set) var allItems: [HouseworkItem] = []
    public private(set) var listenerAnchorDate: Date = .now
    /// ワンショットフェッチ済みの期間。この範囲より過去は未取得のため、必要になった時点で追加取得する
    public private(set) var fetchedRange: ClosedRange<Date>?
    private var streamContinuationDic: [String: AsyncStream<[HouseworkItem]>.Continuation] = [:]
    private var observeTask: Task<Void, Never>?
    /// 進行中の追加フェッチ。同じ期間を重複して取得しないための待ち合わせに使う
    private var pendingFetchTask: Task<Void, Never>?

    // MARK: Dependencies

    private let houseworkClient: HouseworkClient

    // MARK: constant

    private let houseworkObserveKey = "houseworkObserveKey"
    public static let listenerOffset: Int = 3

    // MARK: initialize

    public init(houseworkClient: HouseworkClient) {
        self.houseworkClient = houseworkClient
    }

    /// テスト用：allItems を初期値で設定する
    public init(houseworkClient: HouseworkClient, allItems: [HouseworkItem]) {
        self.houseworkClient = houseworkClient
        self.allItems = allItems
    }

    // MARK: public method

    /// allItems 変化を通知する AsyncStream を生成して返す
    public func createObserver(_ key: String) -> AsyncStream<[HouseworkItem]> {
        let (stream, continuation) = AsyncStream<[HouseworkItem]>.makeStream()
        streamContinuationDic.updateValue(continuation, forKey: key)
        return stream
    }

    public func setupObserver(
        currentTime: Date,
        cohabitantId: String,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy
    ) async {
        listenerAnchorDate = currentTime
        observeTask?.cancel()
        pendingFetchTask?.cancel()
        pendingFetchTask = nil
        await houseworkClient.removeListener(houseworkObserveKey)

        // 1. プランに応じた期間をワンショットフェッチして allItems を初期化
        let lowerBound = storagePolicy.initialFetchLowerBound(currentDate: currentTime, calendar: calendar)
        if let fetchedItems = try? await houseworkClient.fetchItems(cohabitantId, lowerBound, currentTime) {
            allItems = fetchedItems
            fetchedRange = lowerBound ... currentTime
            notifyObservers()
        }

        // 2. ±N日のリアルタイムリスナー起動
        let houseworkListStream = await houseworkClient.snapshotListener(
            houseworkObserveKey,
            cohabitantId,
            currentTime,
            Self.listenerOffset
        )

        observeTask = Task {
            for await currentItems in houseworkListStream {
                // 3. allItems に upsert マージして通知
                upsert(currentItems)
                notifyObservers()
            }
        }
    }

    /// 指定日まで遡って参照できるように、未取得の期間を追加でフェッチする
    ///
    /// プレミアムユーザーが貢献度画面で取得済み期間より過去へ遡った際に呼ぶ。
    /// すでに取得済みの期間内であれば何もしない。
    public func fetchIfNeeded(until targetDate: Date, cohabitantId: String, calendar: Calendar) async {
        // 進行中の追加フェッチがあれば完了を待つ。待っている間に対象期間が取得済みになるケースがある
        if let pendingFetchTask {
            await pendingFetchTask.value
        }

        let targetDay = calendar.startOfDay(for: targetDate)
        guard let fetchedRange, targetDay < fetchedRange.lowerBound else { return }

        // 取得済み範囲と重複しないよう、その前日までを取得する
        let to = calendar.date(byAdding: .day, value: -1, to: fetchedRange.lowerBound) ?? fetchedRange.lowerBound
        let task = Task { [weak self] in
            guard let self else { return }
            await appendItems(cohabitantId: cohabitantId, from: targetDay, to: to)
        }
        pendingFetchTask = task
        await task.value
        pendingFetchTask = nil
    }

}

// MARK: private

private extension HouseworkManager {

    /// 追加フェッチした期間を allItems と fetchedRange に反映する
    func appendItems(cohabitantId: String, from: Date, to: Date) async {
        guard let fetchedItems = try? await houseworkClient.fetchItems(cohabitantId, from, to),
              let currentRange = fetchedRange else { return }

        upsert(fetchedItems)
        fetchedRange = min(from, currentRange.lowerBound) ... currentRange.upperBound
        notifyObservers()
    }

    func upsert(_ updatedItems: [HouseworkItem]) {
        var itemsDict = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        for item in updatedItems {
            itemsDict[item.id] = item
        }
        allItems = Array(itemsDict.values)
    }

    func notifyObservers() {
        for (_, continuation) in streamContinuationDic {
            continuation.yield(allItems)
        }
    }

}
