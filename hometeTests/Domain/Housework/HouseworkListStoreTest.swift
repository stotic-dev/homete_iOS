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
        
        // Act
        
        await store.loadHouseworkList(
            currentTime: now,
            cohabitantId: inputCohabitantId,
            calendar: calendar
        )
        
        // Assert
        
        let waiterForUpdateItems = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.items
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }
        
        let inputHouseworkList: [HouseworkItem] = [
            .makeForTest(id: 1, indexedDate: now, expiredAt: now)
        ]
        continuation.yield(inputHouseworkList)
        await waiterForUpdateItems.value
        continuation.finish()
        
        #expect(
            store.items == .init(value: [
                .init(
                    items: inputHouseworkList,
                    metaData: .init(
                        indexedDate: .init(.now, calendar: .japanese),
                        expiredAt: now
                    )
                )
            ])
        )
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
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .pendingApproval,
            executorId: inputExecutor,
            executedAt: requestedAt
        )
        
        await confirmation(expectedCount: 2) { confirmation in
            
            let _: Void = await withCheckedContinuation { continuation in
                
                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in
                            
                            // Assert
                            
                            #expect(item == updatedHouseworkItem)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
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
    
    @Test("実施者、実施日をクリアして家事のステータスを未完了に戻す")
    func returnToIncomplete() async throws {
        
        // Arrange
        
        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "dummyExecutor",
            executedAt: .distantPast
        )
        let requestedAt = Date()
        let updatedHouseworkItem = inputHouseworkItem.updateProperties(
            state: .incomplete,
            executorId: nil,
            executedAt: nil
        )
        
        try await confirmation(expectedCount: 1) { confirmation in
            
            let store = HouseworkListStore(
                houseworkClient: .init(
                    insertOrUpdateItemHandler: { item, cohabitantId in
                        
                        // Assert
                        
                        #expect(item == updatedHouseworkItem)
                        #expect(cohabitantId == inputCohabitantId)
                        confirmation()
                    }
                ),
                cohabitantPushNotificationClient: .init { _, _ in
                    
                    Issue.record()
                },
                items: [.makeForTest(items: [inputHouseworkItem])],
                cohabitantId: inputCohabitantId
            )
            
            // Act
            
            try await store.returnToIncomplete(
                target: inputHouseworkItem,
                now: requestedAt
            )
        }
    }
    
    @Test("家事削除時は家事を削除するAPIを実行する")
    func remove() async throws {

        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(id: 1)

        try await confirmation { confirmation in

            let store = HouseworkListStore(
                houseworkClient: .init(removeItemHandler: { item, cohabitantId in

                    // Assert

                    #expect(item == inputHouseworkItem)
                    #expect(cohabitantId == inputCohabitantId)
                    confirmation()
                }),
                cohabitantPushNotificationClient: .previewValue,
                items: [.makeForTest(items: [inputHouseworkItem])],
                cohabitantId: inputCohabitantId
            )

            // Act

            try await store.remove(inputHouseworkItem)
        }
    }

    @Test("家事を承認すると、承認情報を更新しパートナーに通知を送信する")
    // swiftlint:disable:next function_body_length
    func approved() async throws {

        // Arrange

        let inputHouseworkItem = HouseworkItem.makeForTest(
            id: 1,
            state: .pendingApproval,
            executorId: "executorId",
            executedAt: .distantPast
        )
        let approvedAt = Date()
        let inputReviewer = Account(
            id: "reviewerId",
            userName: "レビュアー",
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputComment = "お疲れ様でした！"
        let updatedHouseworkItem = inputHouseworkItem.updateApproved(
            at: approvedAt,
            reviewer: inputReviewer.id,
            comment: inputComment
        )
        let expectedNotificationContent = PushNotificationContent.approvedMessage(
            reviwerName: inputReviewer.userName,
            houseworkTitle: inputHouseworkItem.title,
            comment: inputComment
        )

        await confirmation(expectedCount: 2) { confirmation in

            let _: Void = await withCheckedContinuation { continuation in

                let store = HouseworkListStore(
                    houseworkClient: .init(
                        insertOrUpdateItemHandler: { item, cohabitantId in

                            // Assert

                            #expect(item == updatedHouseworkItem)
                            #expect(cohabitantId == inputCohabitantId)
                            confirmation()
                        }
                    ),
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

                    try await store.approved(
                        target: inputHouseworkItem,
                        now: approvedAt,
                        reviwer: inputReviewer,
                        comment: inputComment
                    )
                }
            }
        }
    }
}
