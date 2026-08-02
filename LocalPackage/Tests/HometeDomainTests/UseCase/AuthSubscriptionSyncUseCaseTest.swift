//
//  AuthSubscriptionSyncUseCaseTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

@MainActor
struct AuthSubscriptionSyncUseCaseTest {

    @Test("サインイン成功時にアカウントをロードし、サブスクリプション状態を同期する")
    func syncOnSignedInSuccess() async {
        await confirmation(expectedCount: 2) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let inputAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            let accountInfoClient = AccountInfoClient(fetch: {
                confirmation()
                #expect($0 == inputAuthResult.id)
                return inputAccount
            })
            let purchaseClient = PurchaseClient(
                logIn: {
                    confirmation()
                    #expect($0 == inputAccount.id)
                },
                fetchEntitlementInfo: {
                    EntitlementInfo(isActive: true)
                }
            )
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let subscriptionStore = SubscriptionStore(purchaseClient: purchaseClient)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                subscriptionStore: subscriptionStore
            )

            let actual = await useCase.syncOnSignedIn(inputAuthResult)

            #expect(actual == inputAccount)
            #expect(accountStore.account == inputAccount)
            #expect(subscriptionStore.isPremium)
        }
    }

    @Test("サインイン成功時にアカウントが取得できない場合はサブスクリプションにログインしない")
    func syncOnSignedInAccountNotFound() async {
        await confirmation(expectedCount: 0) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let accountInfoClient = AccountInfoClient(fetch: { _ in nil })
            let purchaseClient = PurchaseClient(logIn: { _ in
                confirmation()
            })
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: AccountStore(accountInfoClient: accountInfoClient),
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient)
            )

            let actual = await useCase.syncOnSignedIn(inputAuthResult)

            #expect(actual == nil)
        }
    }

    @Test("サインアウト後、次のサインインでアカウント取得に失敗した場合は前ユーザーの情報でサブスクリプションにログインしない")
    func syncOnSignedInAfterSignedOutWithFetchFailure() async {
        await confirmation(expectedCount: 0) { confirmation in
            let previousAccount = Account(
                id: "previousAccountId",
                userName: "previousUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            let accountInfoClient = AccountInfoClient(fetch: { _ in throw DomainError.other })
            let purchaseClient = PurchaseClient(logIn: { _ in
                confirmation()
            })
            let accountStore = AccountStore(accountInfoClient: accountInfoClient, account: previousAccount)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient)
            )

            await useCase.syncOnSignedOut()

            let actual = await useCase.syncOnSignedIn(AccountAuthResult(id: "newAccountId"))

            #expect(actual == nil)
            #expect(accountStore.account == nil)
        }
    }

    @Test("サインアウト時にアカウント情報とサブスクリプション状態をクリアする")
    func syncOnSignedOut() async {
        await confirmation(expectedCount: 1) { confirmation in
            let staleAccount = Account(
                id: "previousAccountId",
                userName: "previousUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            let purchaseClient = PurchaseClient(logOut: {
                confirmation()
            })
            let accountStore = AccountStore(account: staleAccount)
            let subscriptionStore = SubscriptionStore(
                purchaseClient: purchaseClient,
                entitlementInfo: EntitlementInfo(isActive: true)
            )
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                subscriptionStore: subscriptionStore
            )

            await useCase.syncOnSignedOut()

            #expect(accountStore.account == nil)
            #expect(subscriptionStore.entitlementInfo == nil)
        }
    }

}
