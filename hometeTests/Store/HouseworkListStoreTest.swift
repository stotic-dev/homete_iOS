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
    
    @Test("家事の完了確認を依頼すると、パートナーにその旨Push通知を送信する")
    func requestReview() async throws {
        
        // Arrange
        
        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)
        let expectedNotificationContent = PushNotificationContent(
            title: "確認が必要な家事があります",
            message: "問題なければ「\(inputHouseworkItem.title)」の完了に感謝を伝えましょう！"
        )
        let requestedAt = Date()
        let inputExecutor = "dummyExecutor"
        let updatedHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            indexedDate: inputHouseworkItem.indexedDate,
            state: .pendingApproval,
            executorId: inputExecutor,
            executedAt: requestedAt,
            expiredAt: inputHouseworkItem.expiredAt
        )
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let _: Void = await withCheckedContinuation { continuation in
                
                let store = HouseworkListStore(
                    houseworkClient: .init(insertOrUpdateItemHandler: { item, cohabitantId in
                        
                        // Assert
                        
                        #expect(item == updatedHouseworkItem)
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
                    items: [.makeForTest(items: [inputHouseworkItem])],
                    cohabitantId: inputCohabitantId
                )
                
                // Act
                
                Task {
                    
                    try await store.requestReview(
                        target: inputHouseworkItem,
                        now: requestedAt,
                        executor: inputExecutor
                    )
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
