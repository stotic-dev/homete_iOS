//
//  CohabitantStoreTest.swift
//  hometeTests
//
//  Created by Taichi Sato on 2026/01/12.
//

import Testing
import Observation
@testable import homete

@MainActor
struct CohabitantStoreTest {

    private let inputCohabitantId = "testCohabitantId"
    private let inputListenerId = "cohabitantListenerKey"

    @Test("パートナーの監視中に、まだキャッシュしていないメンバーの場合はパートナーのリストにキャッシュとして追加する")
    func addSnapshotListenerIfNeeded_add_member_case() async throws {

        // Arrange

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
            members: [newMemberId]
        )

        let (stream, continuation) = AsyncStream<[CohabitantData]>.makeStream()

        let store = CohabitantStore(
            appDependencies: .init(
                accountInfoClient: .init(fetch: { userId in

                    // Assert

                    #expect(userId == newMemberId)
                    return expectedAccount
                }),
                cohabitantClient: .init(
                    addSnapshotListener: { listenerId, cohabitantId in

                        #expect(listenerId == inputListenerId)
                        #expect(cohabitantId == inputCohabitantId)
                        return stream
                    }
                )
            )
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

        #expect(store.members.value.count == 1)
        #expect(store.members.value.contains(.init(id: newMemberId, userName: newMemberUserName)))
    }
}
