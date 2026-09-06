//
//  CohabitantStoreTest.swift
//  hometeTests
//
//  Created by Taichi Sato on 2026/01/12.
//

@testable import HometeDomain
import Observation
import Testing

@MainActor
struct CohabitantStoreTest {

    private let inputCohabitantId = "testCohabitantId"
    private let inputListenerId = "cohabitantListenerKey"

    @Test("パートナーの監視中に、まだキャッシュしていないメンバーの場合はパートナーのリストにキャッシュとして追加する")
    func addSnapshotListenerIfNeeded_add_member_case() async {
        // Arrange

        let selfId = "selfId"
        let newMemberId = "newMemberId"
        let newMemberUserName = "新しいメンバー"
        let expectedAccount = Account(
            id: newMemberId,
            userName: newMemberUserName,
            fcmToken: nil,
            cohabitantId: inputCohabitantId
        )
        let inputCohabitantData = CohabitantData(
            id: inputCohabitantId,
            members: [selfId, newMemberId]
        )

        let (stream, continuation) = AsyncThrowingStream<CohabitantData?, Error>.makeStream()

        let store = CohabitantStore(
            members: [.init(id: selfId, userName: "自分")],
            ownId: selfId,
            cohabitantClient: .init(
                addSnapshotListener: { listenerId, cohabitantId in
                    #expect(listenerId == inputListenerId)
                    #expect(cohabitantId == inputCohabitantId)
                    return stream
                }
            ),
            accountInfoClient: .init(fetch: { userId in
                // Assert

                #expect(userId == newMemberId)
                return expectedAccount
            })
        )

        // Act

        await store.addSnapshotListenerIfNeeded(inputCohabitantId)

        // Assert

        let waiterForUpdateMembers = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.members
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }

        continuation.yield(inputCohabitantData)
        await waiterForUpdateMembers.value
        continuation.finish()
        await store.removeSnapshotListener()

        #expect(store.members.value.count == 2)
        #expect(store.members.value.contains(.init(id: newMemberId, userName: newMemberUserName)))
    }

    @Test("監視中のストリームがエラーで終了した場合は、ロード状態を失敗にする")
    func addSnapshotListenerIfNeeded_stream_failure_case() async {
        // Arrange

        let (stream, continuation) = AsyncThrowingStream<CohabitantData?, Error>.makeStream()
        let store = CohabitantStore(
            cohabitantClient: .init(addSnapshotListener: { _, _ in stream })
        )
        await store.addSnapshotListenerIfNeeded(inputCohabitantId)

        let waiterForLoadState = Task {
            await withCheckedContinuation { continuation in
                ObservationHelper.continuousObservationTracking {
                    store.loadState
                } onChange: {
                    continuation.resume(returning: ())
                }
            }
        }

        // Act

        continuation.finish(throwing: DomainError.noNetwork)

        // Assert

        await waiterForLoadState.value
        #expect(store.loadState == .failed(.noNetwork))
    }

    @Test("エラーで監視が終了したあとに再度監視を開始すると、リスナーが再登録される")
    func addSnapshotListenerIfNeeded_retry_after_failure_case() async {
        // Arrange

        let (stream, continuation) = AsyncThrowingStream<CohabitantData?, Error>.makeStream()
        continuation.finish(throwing: DomainError.noNetwork)

        await confirmation(expectedCount: 2) { confirmation in
            let store = CohabitantStore(
                cohabitantClient: .init(addSnapshotListener: { _, _ in
                    confirmation()
                    return stream
                })
            )
            await store.addSnapshotListenerIfNeeded(inputCohabitantId)
            // 失敗の処理が終わるまで、リスナータスクに実行機会を与える
            for _ in 0 ..< 10 where store.loadState != .failed(.noNetwork) {
                await Task.yield()
            }

            // Act

            await store.addSnapshotListenerIfNeeded(inputCohabitantId)
        }
    }

}
