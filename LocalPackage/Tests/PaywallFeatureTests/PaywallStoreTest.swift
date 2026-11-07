//
//  PaywallStoreTest.swift
//  PaywallFeatureTests
//

import HometeDomain
@testable import PaywallFeature
import Testing

@MainActor
struct PaywallStoreTest {

    private let monthlyPackage = PurchasePackage(
        id: "$rc_monthly",
        productIdentifier: "premium_monthly",
        period: .monthly,
        localizedPrice: "¥300",
        localizedPricePerMonth: nil,
        introductoryOffer: nil
    )
    private let yearlyPackage = PurchasePackage(
        id: "$rc_annual",
        productIdentifier: "premium_yearly",
        period: .yearly,
        localizedPrice: "¥3,000",
        localizedPricePerMonth: "¥250",
        introductoryOffer: nil
    )
    private let purchasedInfo = EntitlementInfo(
        isActive: true,
        productIdentifier: "premium_yearly",
        expirationDate: nil,
        willRenew: true
    )

    // MARK: プランの取得

    @Test("プランの一覧を取得したら一覧を出し、年額を選ぶ")
    func loadSelectsYearly() async {
        // Arrange

        let offering = PurchaseOffering(packages: [monthlyPackage, yearlyPackage])
        let store = makeStore(purchaseClient: .init(fetchOffering: { offering }))

        // Act

        await store.load()

        // Assert

        #expect(store.phase == .loaded(offering))
        #expect(store.selectedPackageId == "$rc_annual")
    }

    @Test("年額を契約中なら、契約中でない月額を選ぶ")
    func loadSkipsSubscribedPackage() async {
        // Arrange

        let offering = PurchaseOffering(packages: [monthlyPackage, yearlyPackage])
        let store = makeStore(
            purchaseClient: .init(fetchOffering: { offering }),
            subscriptionStore: SubscriptionStore(entitlementInfo: purchasedInfo)
        )

        // Act

        await store.load()

        // Assert

        #expect(store.phase == .loaded(offering))
        #expect(store.selectedPackageId == "$rc_monthly")
    }

    @Test("プランの一覧を取得できなかったら、取得の失敗を出し、エラーを記録する")
    func loadFailure() async {
        await confirmation(expectedCount: 1) { confirmation in
            // Arrange

            let store = makeStore(
                purchaseClient: .init(fetchOffering: { throw DomainError.noNetwork }),
                errorReportClient: .init { error, context in
                    confirmation()
                    #expect(error as? DomainError == .noNetwork)
                    #expect(context == ["operation": "fetch_offering"])
                }
            )

            // Act

            await store.load()

            // Assert

            #expect(store.phase == .loadFailed)
        }
    }

    @Test("プランが1つも無ければ、取得の失敗を出し、エラーを記録する")
    func loadEmptyOffering() async {
        await confirmation(expectedCount: 1) { confirmation in
            // Arrange

            let store = makeStore(
                purchaseClient: .init(fetchOffering: { PurchaseOffering(packages: []) }),
                errorReportClient: .init { error, context in
                    confirmation()
                    #expect(error as? PurchaseError == .offeringNotFound)
                    #expect(context == ["operation": "fetch_offering"])
                }
            )

            // Act

            await store.load()

            // Assert

            #expect(store.phase == .loadFailed)
        }
    }

    // MARK: 購入

    @Test("購入が完了したら、お礼を出す")
    func purchaseCompleted() async {
        // Arrange

        let store = await makeLoadedStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            fetchOffering: { PurchaseOffering(packages: [monthlyPackage, yearlyPackage]) },
            purchase: { packageId in
                #expect(packageId == "$rc_annual")
                return .purchased(purchasedInfo)
            }
        ))

        // Act

        await store.purchase()

        // Assert

        #expect(store.phase == .completed)
        #expect(store.alert == nil)
    }

    @Test("購入をキャンセルしたら、プランの一覧を出したままにする")
    func purchaseCancelled() async {
        // Arrange

        let offering = PurchaseOffering(packages: [monthlyPackage, yearlyPackage])
        let store = await makeLoadedStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            fetchOffering: { offering },
            purchase: { _ in .cancelled }
        ))

        // Act

        await store.purchase()

        // Assert

        #expect(store.phase == .loaded(offering))
        #expect(store.alert == nil)
    }

    @Test("購入が承認待ちになったら、承認待ちのアラートを出す")
    func purchasePending() async {
        // Arrange

        let store = await makeLoadedStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            fetchOffering: { PurchaseOffering(packages: [yearlyPackage]) },
            purchase: { _ in .pending }
        ))

        // Act

        await store.purchase()

        // Assert

        #expect(store.alert == .purchasePending)
    }

    @Test("購入に失敗したら、失敗のアラートを出し、エラーを記録する")
    func purchaseFailure() async {
        await confirmation(expectedCount: 1) { confirmation in
            // Arrange

            let store = await makeLoadedStore(
                purchaseClient: .init(
                    appUserId: { "testAccountId" },
                    fetchOffering: { PurchaseOffering(packages: [yearlyPackage]) },
                    purchase: { _ in throw DomainError.other }
                ),
                errorReportClient: .init { error, context in
                    confirmation()
                    #expect(error as? DomainError == .other)
                    #expect(context == ["operation": "purchase", "package_id": "$rc_annual"])
                }
            )

            // Act

            await store.purchase()

            // Assert

            #expect(store.alert == .purchaseFailed)
        }
    }

    // MARK: 復元

    @Test("復元できたら、お礼を出す")
    func restoreSucceeded() async {
        // Arrange

        let store = makeStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            restorePurchases: { purchasedInfo }
        ))

        // Act

        await store.restore()

        // Assert

        #expect(store.phase == .completed)
        #expect(store.alert == nil)
    }

    @Test("復元できる購入が無ければ、見つからなかったアラートを出す")
    func restoreNotFound() async {
        // Arrange

        let store = makeStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            restorePurchases: {
                EntitlementInfo(isActive: false, productIdentifier: "", expirationDate: nil, willRenew: false)
            }
        ))

        // Act

        await store.restore()

        // Assert

        #expect(store.alert == .restoreNotFound)
    }

    @Test("復元に失敗したら、失敗のアラートを出す")
    func restoreFailure() async {
        // Arrange

        let store = makeStore(purchaseClient: .init(
            appUserId: { "testAccountId" },
            restorePurchases: { throw DomainError.other }
        ))

        // Act

        await store.restore()

        // Assert

        #expect(store.alert == .restoreFailed)
    }

}

private extension PaywallStoreTest {

    /// - Note: 購入・復元の`SubscriptionStore`にも同じ`purchaseClient`を渡す
    func makeStore(
        purchaseClient: PurchaseClient,
        errorReportClient: ErrorReportClient = .previewValue,
        subscriptionStore: SubscriptionStore? = nil
    ) -> PaywallStore {
        PaywallStore(
            accountId: "testAccountId",
            purchaseClient: purchaseClient,
            errorReportClient: errorReportClient,
            subscriptionStore: subscriptionStore ?? SubscriptionStore(purchaseClient: purchaseClient)
        )
    }

    /// プランの一覧を取得し終えたStoreを作る
    func makeLoadedStore(
        purchaseClient: PurchaseClient,
        errorReportClient: ErrorReportClient = .previewValue
    ) async -> PaywallStore {
        let store = makeStore(purchaseClient: purchaseClient, errorReportClient: errorReportClient)
        await store.load()
        return store
    }

}
