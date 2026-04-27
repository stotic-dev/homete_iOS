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
    private var streamContinuationDic: [String: AsyncStream<[HouseworkItem]>.Continuation] = [:]
    private var observeTask: Task<Void, Never>?
    
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

    public func setupObserver(currentTime: Date, cohabitantId: String, calendar: Calendar) async {
        listenerAnchorDate = currentTime
        observeTask?.cancel()
        await houseworkClient.removeListener(houseworkObserveKey)

        // 1. 直近1年分をワンショットフェッチして allItems を初期化
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: currentTime) ?? currentTime
        if let fetchedItems = try? await houseworkClient.fetchItems(cohabitantId, oneYearAgo, currentTime) {
            allItems = fetchedItems
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
}

// MARK: private

private extension HouseworkManager {

    func upsert(_ updatedItems: [HouseworkItem]) {
        
        var itemsDict = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        for item in updatedItems {
            
            itemsDict[item.id] = item
        }
        allItems = Array(itemsDict.values)
    }

    func notifyObservers() {
        
        streamContinuationDic.forEach { _, continuation in
            
            continuation.yield(allItems)
        }
    }
}
