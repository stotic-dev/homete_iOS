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
                    return EntitlementInfo(
                        isActive: true,
                        productIdentifier: "premium_monthly",
                        expirationDate: nil,
                        willRenew: true
                    )
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
                entitlementInfo: EntitlementInfo(
                    isActive: true,
                    productIdentifier: "premium_monthly",
                    expirationDate: nil,
                    willRenew: true
                )
            )

            await store.logOut()

            #expect(store.entitlementInfo == nil)
            #expect(!store.isPremium)
        }
    }

    @Test("エンタイトルメント取得に失敗した場合は状態を更新しない")
    func refreshFailure() async {
        let existingInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )
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

    @Test("サブスクリプション管理画面の表示をPurchaseClientに委譲する")
    func showManageSubscriptions() async {
        await confirmation(expectedCount: 1) { confirmation in
            let purchaseClient = PurchaseClient(showManageSubscriptions: {
                confirmation()
            })
            let store = SubscriptionStore(purchaseClient: purchaseClient)

            await store.showManageSubscriptions()
        }
    }

    @Test("購入の復元に成功した場合、復元結果をエンタイトルメント状態へ反映する")
    func restorePurchasesSuccess() async throws {
        // Arrange

        let restoredInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_yearly",
            expirationDate: nil,
            willRenew: true
        )
        let purchaseClient = PurchaseClient(restorePurchases: { restoredInfo })
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = try await store.restorePurchases()

        // Assert

        #expect(actual == true)
        let expected = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_yearly",
            expirationDate: nil,
            willRenew: true
        )
        #expect(store.entitlementInfo == expected)
    }

    @Test("復元できる購入がない場合、falseを返す")
    func restorePurchasesWithoutActiveEntitlement() async throws {
        // Arrange

        let purchaseClient = PurchaseClient(restorePurchases: {
            EntitlementInfo(
                isActive: false,
                productIdentifier: "",
                expirationDate: nil,
                willRenew: false
            )
        })
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = try await store.restorePurchases()

        // Assert

        #expect(actual == false)
    }

    @Test("購入の復元に失敗した場合、呼び出し元へエラーを伝播する")
    func restorePurchasesFailure() async {
        // Arrange

        let existingInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )
        let purchaseClient = PurchaseClient(restorePurchases: {
            throw DomainError.other
        })
        let store = SubscriptionStore(
            purchaseClient: purchaseClient,
            entitlementInfo: existingInfo
        )

        // Act
        // Assert

        await #expect(throws: DomainError.other) {
            try await store.restorePurchases()
        }
        #expect(store.entitlementInfo == existingInfo)
    }

}
