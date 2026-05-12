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

        let (stream, continuation) = AsyncStream<[CohabitantData]>.makeStream()

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

        continuation.yield([inputCohabitantData])
        await waiterForUpdateMembers.value
        continuation.finish()
        await store.removeSnapshotListener()

        #expect(store.members.value.count == 2)
        #expect(store.members.value.contains(.init(id: newMemberId, userName: newMemberUserName)))
    }

}
