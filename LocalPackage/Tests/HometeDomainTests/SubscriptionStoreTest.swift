//
//  SubscriptionStoreTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

@MainActor
struct SubscriptionStoreTest {

    @Test("ログイン成功時にエンタイトルメント状態を反映し、is_premiumユーザープロパティを設定する")
    func logInSuccess() async {
        await confirmation(expectedCount: 3) { confirmation in
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
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(setUserProperty: { property in
                    confirmation()
                    #expect(property == .isPremium(true))
                })
            )

            await store.logIn(inputAccountId)

            #expect(store.isPremium)
        }
    }

    @Test("購入者がすでにアカウントになっていれば、ログインし直さずにtrueを返す")
    func ensureLoggedInAlreadyLoggedIn() async {
        // Arrange

        let purchaseClient = PurchaseClient(
            logIn: { _ in Issue.record("ログインし直さない") },
            appUserId: { "testAccountId" }
        )
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = await store.ensureLoggedIn("testAccountId")

        // Assert

        #expect(actual)
    }

    @Test(
        "購入者がアカウントになっていなければログインし直し、成功したらエンタイトルメント状態を反映してtrueを返す",
        arguments: [nil, "$RCAnonymousID:abc"]
    )
    func ensureLoggedInRetrySuccess(currentAppUserId: String?) async {
        // Arrange

        let entitlementInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )

        // Act

        let (actual, store) = await confirmation(expectedCount: 1) { confirmation in
            let purchaseClient = PurchaseClient(
                logIn: {
                    confirmation()
                    #expect($0 == "testAccountId")
                },
                appUserId: { currentAppUserId },
                fetchEntitlementInfo: { entitlementInfo }
            )
            let store = SubscriptionStore(purchaseClient: purchaseClient)
            return await (store.ensureLoggedIn("testAccountId"), store)
        }

        // Assert

        #expect(actual)
        #expect(store.entitlementInfo == entitlementInfo)
    }

    @Test("購入者がアカウントになっておらず、ログインし直しにも失敗したらfalseを返す")
    func ensureLoggedInRetryFailure() async {
        // Arrange

        let purchaseClient = PurchaseClient(
            logIn: { _ in throw DomainError.noNetwork },
            appUserId: { "$RCAnonymousID:abc" }
        )
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = await store.ensureLoggedIn("testAccountId")

        // Assert

        #expect(!actual)
    }

    @Test("ログアウト時にエンタイトルメント状態をクリアし、is_premiumユーザープロパティをfalseに更新する")
    func logOut() async {
        await confirmation(expectedCount: 2) { confirmation in
            let purchaseClient = PurchaseClient(logOut: {
                confirmation()
            })
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(setUserProperty: { property in
                    confirmation()
                    #expect(property == .isPremium(false))
                }),
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

    @Test("エンタイトルメント取得に成功した場合、is_premiumユーザープロパティを更新する")
    func refreshSuccess() async {
        await confirmation(expectedCount: 1) { confirmation in
            let purchaseClient = PurchaseClient(fetchEntitlementInfo: {
                EntitlementInfo(
                    isActive: true,
                    productIdentifier: "premium_monthly",
                    expirationDate: nil,
                    willRenew: true
                )
            })
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(setUserProperty: { property in
                    confirmation()
                    #expect(property == .isPremium(true))
                })
            )

            await store.refresh()
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

    @Test("サブスクリプション管理画面の表示に成功したら、subscriptionイベントを送信する")
    func showManageSubscriptions() async {
        await confirmation(expectedCount: 2) { confirmation in
            let purchaseClient = PurchaseClient(showManageSubscriptions: {
                confirmation()
            })
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(log: { event in
                    confirmation()
                    #expect(event == .subscription(.manageOpened(isSuccess: true)))
                })
            )

            await store.showManageSubscriptions()
        }
    }

    @Test("サブスクリプション管理画面の表示に失敗したら、subscriptionイベントを失敗として送信する")
    func showManageSubscriptionsFailure() async {
        await confirmation(expectedCount: 1) { confirmation in
            let purchaseClient = PurchaseClient(showManageSubscriptions: {
                throw DomainError.other
            })
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(log: { event in
                    confirmation()
                    #expect(event == .subscription(.manageOpened(isSuccess: false)))
                })
            )

            await store.showManageSubscriptions()
        }
    }

    @Test("購入の復元に成功した場合、復元結果をエンタイトルメント状態へ反映し、is_premiumユーザープロパティとsubscriptionイベントを送信する")
    func restorePurchasesSuccess() async throws {
        // Arrange

        let restoredInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_yearly",
            expirationDate: nil,
            willRenew: true
        )
        let purchaseClient = PurchaseClient(appUserId: { "testAccountId" }, restorePurchases: { restoredInfo })

        let store = try await confirmation(expectedCount: 2) { confirmation in
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(
                    setUserProperty: { property in
                        confirmation()
                        #expect(property == .isPremium(true))
                    },
                    log: { event in
                        confirmation()
                        #expect(event == .subscription(.restore(isSuccess: true)))
                    }
                )
            )

            // Act

            try await store.restorePurchases(for: "testAccountId")

            return store
        }

        // Assert

        #expect(store.entitlementInfo == restoredInfo)
    }

    @Test("復元できる購入がない場合、falseを返す")
    func restorePurchasesWithoutActiveEntitlement() async throws {
        // Arrange

        let purchaseClient = PurchaseClient(appUserId: { "testAccountId" }, restorePurchases: {
            EntitlementInfo(
                isActive: false,
                productIdentifier: "",
                expirationDate: nil,
                willRenew: false
            )
        })
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = try await store.restorePurchases(for: "testAccountId")

        // Assert

        #expect(actual == false)
    }

    @Test("購入の復元に失敗した場合、呼び出し元へエラーを伝播し、subscriptionイベントを失敗として送信する")
    func restorePurchasesFailure() async {
        // Arrange

        let existingInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_monthly",
            expirationDate: nil,
            willRenew: true
        )
        let purchaseClient = PurchaseClient(appUserId: { "testAccountId" }, restorePurchases: {
            throw DomainError.other
        })
        let store = await confirmation(expectedCount: 1) { confirmation in
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(log: { event in
                    confirmation()
                    #expect(event == .subscription(.restore(isSuccess: false)))
                }),
                entitlementInfo: existingInfo
            )

            // Act

            await #expect(throws: DomainError.other) {
                try await store.restorePurchases(for: "testAccountId")
            }

            return store
        }

        // Assert

        #expect(store.entitlementInfo == existingInfo)
    }

    @Test("購入者をアカウントにできない場合、復元せずにエラーを伝播し、subscriptionイベントを失敗として送信する")
    func restorePurchasesNotLoggedIn() async {
        // Arrange

        let purchaseClient = PurchaseClient(
            logIn: { _ in throw DomainError.noNetwork },
            appUserId: { "$RCAnonymousID:abc" },
            restorePurchases: {
                Issue.record("復元しない")
                return EntitlementInfo(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
            }
        )

        await confirmation(expectedCount: 1) { confirmation in
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(log: { event in
                    confirmation()
                    #expect(event == .subscription(.restore(isSuccess: false)))
                })
            )

            // Act & Assert

            await #expect(throws: PurchaseAccountError.notLoggedIn) {
                try await store.restorePurchases(for: "testAccountId")
            }
        }
    }

}
