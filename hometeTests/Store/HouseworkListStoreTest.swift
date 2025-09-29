//
//  HouseworkListStoreTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/09/29.
//

import Foundation
import Testing

@testable import homete

@MainActor
struct HouseworkListStoreTest {

    @Test("家事リストのロードを行うと最新の家事リストを常に監視し続ける")
    func loadHouseworkList() async throws {
        
        let inputId = "houseworkObserveKey"
        let inputCohabitantId = "cohabitantId"
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let (stream, continuation) = AsyncStream<[HouseworkItem]>.makeStream()
        let store = HouseworkListStore(
            houseworkClient: .init(snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in
                
                #expect(id == inputId)
                #expect(cohabitantId == inputCohabitantId)
                #expect(anchorDate == now)
                #expect(offset == 3)
                return stream
            })
        )
        
        await confirmation(expectedCount: 2) { confirmation in
            
            async let loadHouseworkListTask: () = store.loadHouseworkList(
                currentTime: now,
                cohabitantId: inputCohabitantId,
                calendar: calendar
            )
            
            continuousObservationTracking {
                
                store.items
            } onChange: {
                
                confirmation()
            }
            
            var inputHouseworkList: [HouseworkItem] = [
                .init(id: "id1", indexedDate: now, title: "title1", point: 10, state: .incomplete, expiredAt: now)
            ]
            continuation.yield(inputHouseworkList)
            
            inputHouseworkList.append(
                .init(id: "id2", indexedDate: now, title: "title2", point: 100, state: .incomplete, expiredAt: now)
            )
            continuation.yield(inputHouseworkList)
            
            continuation.finish()
            await loadHouseworkListTask
            
            #expect(
                store.items == [
                    .init(items: inputHouseworkList, metaData: .init(indexedDate: now, expiredAt: now))
                ]
            )
        }
    }

}

private extension HouseworkListStoreTest {
    
    nonisolated func continuousObservationTracking<T>(
        _ apply: @escaping () -> T,
        onChange: @escaping (@Sendable () -> Void)
    ) {
        
        _ = withObservationTracking(apply) {
            
            onChange()
            continuousObservationTracking(apply, onChange: onChange)
        }
    }
}
