//
//  SubscriptionStoreTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

@MainActor
struct SubscriptionStoreTest {

    @Test("ログイン成功時にエンタイトルメント状態を反映する")
    func logInSuccess() async {
        await confirmation(expectedCount: 2) { confirmation in
            let inputAccountId = "testAccountId"
            let purchaseClient = PurchaseClient(
                logIn: {
                    confirmation()
                    #expect($0 == inputAccountId)
                },
                fetchEntitlementInfo: {
                    confirmation()
                    return EntitlementInfo(isActive: true)
                }
            )
            let store = SubscriptionStore(purchaseClient: purchaseClient)

            await store.logIn(inputAccountId)

            #expect(store.isPremium)
        }
    }

    @Test("ログアウト時にエンタイトルメント状態をクリアする")
    func logOut() async {
        await confirmation(expectedCount: 1) { confirmation in
            let purchaseClient = PurchaseClient(logOut: {
                confirmation()
            })
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                entitlementInfo: EntitlementInfo(isActive: true)
            )

            await store.logOut()

            #expect(store.entitlementInfo == nil)
            #expect(!store.isPremium)
        }
    }

    @Test("エンタイトルメント取得に失敗した場合は状態を更新しない")
    func refreshFailure() async {
        let existingInfo = EntitlementInfo(isActive: true)
        let purchaseClient = PurchaseClient(fetchEntitlementInfo: {
            throw DomainError.other
        })
        let store = SubscriptionStore(
            purchaseClient: purchaseClient,
            entitlementInfo: existingInfo
        )

        await store.refresh()

        #expect(store.entitlementInfo == existingInfo)
    }

}
