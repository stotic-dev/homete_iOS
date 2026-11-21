//
//  SubscriptionStorePurchaseTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

@MainActor
struct SubscriptionStorePurchaseTest {

    @Test("購入が完了したら、購入後のエンタイトルメント状態を反映し、is_premiumユーザープロパティを設定する")
    func purchaseCompleted() async throws {
        // Arrange

        let purchasedInfo = EntitlementInfo(
            isActive: true,
            productIdentifier: "premium_yearly",
            expirationDate: nil,
            willRenew: true
        )

        let (actual, store) = try await confirmation(expectedCount: 2) { confirmation in
            let purchaseClient = PurchaseClient(
                appUserId: { "testAccountId" },
                purchase: { packageId in
                    confirmation()
                    #expect(packageId == "$rc_annual")
                    return .purchased(purchasedInfo)
                }
            )
            let store = SubscriptionStore(
                purchaseClient: purchaseClient,
                analyticsClient: .init(setUserProperty: { property in
                    confirmation()
                    #expect(property == .isPremium(true))
                })
            )

            // Act

            return try await (store.purchase("$rc_annual", for: "testAccountId"), store)
        }

        // Assert

        #expect(actual == .purchased(purchasedInfo))
        #expect(store.entitlementInfo == purchasedInfo)
    }

    @Test("購入をキャンセルしたら、エンタイトルメント状態を変えずにキャンセルを返す")
    func purchaseCancelled() async throws {
        // Arrange

        let purchaseClient = PurchaseClient(
            appUserId: { "testAccountId" },
            purchase: { _ in .cancelled }
        )
        let store = SubscriptionStore(
            purchaseClient: purchaseClient,
            analyticsClient: .init(setUserProperty: { _ in Issue.record("ユーザープロパティを更新しない") })
        )

        // Act

        let actual = try await store.purchase("$rc_annual", for: "testAccountId")

        // Assert

        #expect(actual == .cancelled)
        #expect(store.entitlementInfo == nil)
    }

    @Test("購入が承認待ちになったら、エンタイトルメント状態を変えずに承認待ちを返す")
    func purchasePending() async throws {
        // Arrange

        let purchaseClient = PurchaseClient(
            appUserId: { "testAccountId" },
            purchase: { _ in .pending }
        )
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act

        let actual = try await store.purchase("$rc_annual", for: "testAccountId")

        // Assert

        #expect(actual == .pending)
        #expect(store.entitlementInfo == nil)
    }

    @Test("購入に失敗したら、呼び出し元へエラーを伝播する")
    func purchaseFailure() async {
        // Arrange

        let purchaseClient = PurchaseClient(
            appUserId: { "testAccountId" },
            purchase: { _ in throw DomainError.other }
        )
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act & Assert

        await #expect(throws: DomainError.other) {
            try await store.purchase("$rc_annual", for: "testAccountId")
        }
    }

    @Test("購入者をアカウントにできない場合、購入せずにエラーを伝播する")
    func purchaseNotLoggedIn() async {
        // Arrange

        let purchaseClient = PurchaseClient(
            logIn: { _ in throw DomainError.noNetwork },
            appUserId: { "$RCAnonymousID:abc" },
            purchase: { _ in
                Issue.record("購入しない")
                return .cancelled
            }
        )
        let store = SubscriptionStore(purchaseClient: purchaseClient)

        // Act & Assert

        await #expect(throws: PurchaseAccountError.notLoggedIn) {
            try await store.purchase("$rc_annual", for: "testAccountId")
        }
    }

}
