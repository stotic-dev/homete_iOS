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
    
    private let inputId = "houseworkObserveKey"
    private let inputCohabitantId = "cohabitantId"

    @Test("家事リストのロードを行うと最新の家事リストを常に監視し続ける")
    func loadHouseworkList() async throws {
        
        // Arrange
        
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
            }),
            cohabitantPushNotificationClient: .previewValue
        )
        
        await confirmation(expectedCount: 2) { confirmation in
            
            // Act
            
            async let loadHouseworkListTask: () = store.loadHouseworkList(
                currentTime: now,
                cohabitantId: inputCohabitantId,
                calendar: calendar
            )
            
            // Assert
            
            continuousObservationTracking {
                
                store.items
            } onChange: {
                
                confirmation()
            }
            
            var inputHouseworkList: [HouseworkItem] = [
                .makeForTest(id: 1, indexedDate: now, expiredAt: now)
            ]
            continuation.yield(inputHouseworkList)
            
            inputHouseworkList.append(
                .makeForTest(id: 2, indexedDate: now, expiredAt: now)
            )
            continuation.yield(inputHouseworkList)
            
            continuation.finish()
            await loadHouseworkListTask
            
            #expect(
                store.items == .init(value: [
                    .init(items: inputHouseworkList, metaData: .init(indexedDate: now, expiredAt: now))
                ])
            )
        }
    }
    
    @Test("新しい家事の登録すると、パートナーに通知を送信する")
    func register() async throws {
        
        // Arrange
        
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let expectedNotificationContent = PushNotificationContent(
            title: "新しい家事が登録されました",
            message: inputHouseworkItem.title
        )
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let _: Void = await withCheckedContinuation { continuation in
                
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                        
                        // Assert
                        
                        #expect(item == inputHouseworkItem)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }),
                    cohabitantPushNotificationClient: .init { id, content in
                        
                        // Assert
                        
                        #expect(id == inputCohabitantId)
                        #expect(content == expectedNotificationContent)
                        confirmation()
                        continuation.resume()
                    },
                    cohabitantId: inputCohabitantId
                )
                
                // Act
                
                Task {
                    
                    try await store.register(inputHouseworkItem)
                }
            }
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
