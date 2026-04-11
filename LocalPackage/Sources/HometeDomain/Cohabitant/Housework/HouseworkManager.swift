//
//  HouseworkManager.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/11.
//

import Foundation

public final actor HouseworkManager {
        
    // MARK: Dependencies
    
    private let houseworkClient: HouseworkClient
    
    // MARK: state
    
    private var list: StoredAllHouseworkList
    private var streamContinuationDic: [String: AsyncStream<StoredAllHouseworkList>.Continuation] = [:]
    private var observeTask: Task<Void, Never>?
    
    // MARK: constant
    
    private let houseworkObserveKey = "houseworkObserveKey"
        
    // MARK: initialize
    
    public init(houseworkClient: HouseworkClient, list: StoredAllHouseworkList = .init(value: [])) {
        self.houseworkClient = houseworkClient
        self.list = list
    }
    
    // MARK: public method
    
    /// 家事情報監視用のObesrver生成
    public func createListObserver(_ key: String) -> AsyncStream<StoredAllHouseworkList> {
        let (stream, continuation) = AsyncStream<StoredAllHouseworkList>.makeStream()
        streamContinuationDic.updateValue(continuation, forKey: key)
        return stream
    }
    
    public func setupObserver(currentTime: Date, cohabitantId: String, calendar: Calendar, offset: Int) async {
        observeTask?.cancel()
        await houseworkClient.removeListener(houseworkObserveKey)

        let houseworkListStream = await houseworkClient.snapshotListener(
            houseworkObserveKey,
            cohabitantId,
            currentTime,
            offset
        )

        observeTask = Task {

            for await currentItems in houseworkListStream {

                let currentList = StoredAllHouseworkList.makeMultiDateList(
                    items: currentItems,
                    calendar: calendar
                )
                // 監視中のオブザーバー全てに更新内容を通知
                streamContinuationDic.forEach { _, continuation in
                    continuation.yield(currentList)
                }
            }
        }
    }
}
