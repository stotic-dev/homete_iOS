// swiftlint:disable file_length
//
//  AuthSubscriptionSyncUseCaseTest.swift
//  hometeTests
//

import Foundation
@testable import HometeDomain
import Testing

enum AuthSubscriptionSyncUseCaseTest {

    /// サインイン時の同期
    @MainActor
    struct SignedInCase {}
    /// サインアウト時のクリーンアップ
    @MainActor
    struct SignedOutCase {}
    /// プレミアム状態と家事データ保持期限の同期
    @MainActor
    struct RetentionSyncCase {}

}

/// テストごとに独立したUserDefaultsを用意する
private func makeSyncStateStore(_ suiteName: String) -> HouseworkRetentionSyncStateStore {
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    userDefaults.removePersistentDomain(forName: suiteName)
    return HouseworkRetentionSyncStateStore(userDefaults: userDefaults)
}

extension AuthSubscriptionSyncUseCaseTest.SignedInCase {

    @Test("サインイン成功時にアカウントをロードし、プレミアム状態をアカウントへ反映する")
    func syncOnSignedInSuccess() async {
        await confirmation(expectedCount: 2) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let inputAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            // エンタイトルメントがプレミアムのため、ロードしたアカウントに同期される
            let expectedAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: nil,
                isPremium: true
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
                    EntitlementInfo(
                        isActive: true,
                        productIdentifier: "premium_monthly",
                        expirationDate: nil,
                        willRenew: true
                    )
                }
            )
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let subscriptionStore = SubscriptionStore(purchaseClient: purchaseClient)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: subscriptionStore,
                houseworkManager: .init(houseworkClient: .previewValue)
            )

            let actual = await useCase.syncOnSignedIn(inputAuthResult)

            #expect(actual == expectedAccount)
            #expect(accountStore.account == expectedAccount)
            #expect(subscriptionStore.isPremium)
        }
    }

    @Test("サインイン成功時に自分のアカウントの購読を開始する")
    func syncOnSignedInStartsObservingAccount() async {
        await confirmation(expectedCount: 1) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let inputAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            let accountInfoClient = AccountInfoClient(
                fetch: { _ in inputAccount },
                addSnapshotListener: { _, accountId in
                    confirmation()
                    #expect(accountId == inputAuthResult.id)
                    return .init { $0.finish() }
                }
            )
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let subscriptionStore = SubscriptionStore(purchaseClient: .init())
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: subscriptionStore,
                houseworkManager: .init(houseworkClient: .previewValue)
            )

            _ = await useCase.syncOnSignedIn(inputAuthResult)
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
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient),
                houseworkManager: .init(houseworkClient: .previewValue)
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
            let newAuthResult = AccountAuthResult(id: "newAccountId")
            let accountInfoClient = AccountInfoClient(fetch: { _ in throw DomainError.other })
            let purchaseClient = PurchaseClient(logIn: { _ in
                confirmation()
            })
            let accountStore = AccountStore(accountInfoClient: accountInfoClient, account: previousAccount)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient),
                houseworkManager: .init(houseworkClient: .previewValue)
            )

            await useCase.syncOnSignedOut()

            let actual = await useCase.syncOnSignedIn(newAuthResult)

            #expect(actual == nil)
            #expect(accountStore.account == nil)
        }
    }

    @Test("アカウントのロード中に世代が打ち切られた場合は、購読を開始せずロード結果も破棄する")
    func syncOnSignedInAbortsWhenCancelledDuringLoad() async {
        await confirmation("古いユーザーIDでは購読もサブスクリプションのログインも行わない", expectedCount: 0) { confirmation in
            let staleAuthResult = AccountAuthResult(id: "staleAccountId")
            let staleAccount = Account(
                id: staleAuthResult.id,
                userName: "staleUserName",
                fcmToken: nil,
                cohabitantId: nil
            )
            let accountInfoClient = AccountInfoClient(
                fetch: { _ in staleAccount },
                addSnapshotListener: { _, _ in
                    confirmation()
                    return .init { $0.finish() }
                }
            )
            let purchaseClient = PurchaseClient(logIn: { _ in
                confirmation()
            })
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient),
                houseworkManager: .init(houseworkClient: .previewValue)
            )

            // ロードを待っている間にトークン失効で自動サインアウトした状況を、
            // 世代のTaskをキャンセル済みにしてから走らせることで再現する
            let task = Task { await useCase.syncOnSignedIn(staleAuthResult) }
            task.cancel()

            let actual = await task.value

            #expect(actual == nil)
            #expect(accountStore.account == nil)
        }
    }

}

extension AuthSubscriptionSyncUseCaseTest.SignedOutCase {

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
                entitlementInfo: EntitlementInfo(
                    isActive: true,
                    productIdentifier: "premium_monthly",
                    expirationDate: nil,
                    willRenew: true
                )
            )
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: subscriptionStore,
                houseworkManager: .init(houseworkClient: .previewValue)
            )

            await useCase.syncOnSignedOut()

            #expect(accountStore.account == nil)
            #expect(subscriptionStore.entitlementInfo == nil)
        }
    }

    @Test("サインアウト時に同居人グループと家事の購読を止め、前のユーザーのデータを破棄する")
    func syncOnSignedOutStopsCohabitantAndHouseworkObserving() async {
        await confirmation("同居人グループの購読を解除する") { removedCohabitantListener in
            await confirmation("家事の購読を解除する") { removedHouseworkListener in
                let staleMember = CohabitantMember(id: "staleMemberId", userName: "前のユーザー")
                let cohabitantStore = CohabitantStore(
                    members: [staleMember],
                    ownId: staleMember.id,
                    cohabitantClient: .init(removeSnapshotListener: { _ in
                        removedCohabitantListener()
                    })
                )
                let houseworkManager = HouseworkManager(
                    houseworkClient: .init(removeListenerHandler: { _ in
                        removedHouseworkListener()
                    }),
                    allItems: [.makeForTest(id: 1)]
                )
                let useCase = AuthSubscriptionSyncUseCase(
                    accountStore: AccountStore(),
                    cohabitantStore: cohabitantStore,
                    subscriptionStore: SubscriptionStore(),
                    houseworkManager: houseworkManager
                )

                await useCase.syncOnSignedOut()

                #expect(cohabitantStore.members == CohabitantMemberList(value: [], ownId: ""))
                #expect(await houseworkManager.allItems == [])
            }
        }
    }

    @Test("サインアウト時に、ユーザーに紐づくユーザープロパティとユーザーIDをリセットする")
    func syncOnSignedOutClearsAnalyticsUser() async {
        await confirmation("has_cohabitantをクリアする") { clearedHasCohabitant in
            await confirmation("cohabitant_member_countをクリアする") { clearedMemberCount in
                await confirmation("ユーザーIDをクリアする") { clearedId in
                    let analyticsClient = AnalyticsClient(
                        clearId: {
                            clearedId()
                        },
                        setUserProperty: { property in
                            switch property {
                            case .cleared(.hasCohabitant):
                                clearedHasCohabitant()

                            case .cleared(.cohabitantMemberCount):
                                clearedMemberCount()

                            default:
                                Issue.record("想定外のユーザープロパティが送信された: \(property)")
                            }
                        }
                    )
                    let useCase = AuthSubscriptionSyncUseCase(
                        accountStore: AccountStore(),
                        cohabitantStore: CohabitantStore(),
                        subscriptionStore: SubscriptionStore(),
                        houseworkManager: .init(houseworkClient: .previewValue),
                        analyticsClient: analyticsClient
                    )

                    await useCase.syncOnSignedOut()
                }
            }
        }
    }

}

extension AuthSubscriptionSyncUseCaseTest.RetentionSyncCase {

    @Test("プレミアム状態が変化した場合はアカウントを更新し家事データの保持期限を同期する")
    func syncPremiumStateIfNeededWhenChanged() async {
        await confirmation(expectedCount: 1) { confirmation in
            let inputCohabitantId = "cohabitantId"
            let inputAccount = Account(
                id: "testAccountId",
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: inputCohabitantId,
                isPremium: false
            )
            let expectedAccount = Account(
                id: "testAccountId",
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: inputCohabitantId,
                isPremium: true
            )
            let accountStore = AccountStore(account: inputAccount)
            let subscriptionStore = SubscriptionStore(
                entitlementInfo: EntitlementInfo(
                    isActive: true,
                    productIdentifier: "premium_monthly",
                    expirationDate: nil,
                    willRenew: true
                )
            )
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: subscriptionStore,
                houseworkManager: .init(houseworkClient: .previewValue),
                houseworkClient: .init(syncRetentionHandler: {
                    #expect($0 == inputCohabitantId)
                    confirmation()
                }),
                retentionSyncStateStore: makeSyncStateStore(#function)
            )

            await useCase.syncPremiumStateIfNeeded()

            #expect(accountStore.account == expectedAccount)
        }
    }

    @Test("同期済みの内容と一致する場合は保持期限の同期を行わない")
    func syncPremiumStateIfNeededWhenAlreadySynced() async {
        await confirmation(expectedCount: 0) { confirmation in
            let inputCohabitantId = "cohabitantId"
            let inputAccount = Account(
                id: "testAccountId",
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: inputCohabitantId,
                isPremium: false
            )
            let syncStateStore = makeSyncStateStore(#function)
            syncStateStore.save(.init(cohabitantId: inputCohabitantId, isPremium: false))
            let accountStore = AccountStore(account: inputAccount)
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(),
                houseworkManager: .init(houseworkClient: .previewValue),
                houseworkClient: .init(syncRetentionHandler: { _ in
                    confirmation()
                }),
                retentionSyncStateStore: syncStateStore
            )

            await useCase.syncPremiumStateIfNeeded()

            #expect(accountStore.account == inputAccount)
        }
    }

    @Test("グループ未参加で同期をスキップした場合、グループ参加後に同期される")
    func syncHouseworkRetentionAfterJoiningCohabitant() async {
        await confirmation(expectedCount: 1) { confirmation in
            let inputCohabitantId = "cohabitantId"
            let accountStore = AccountStore(account: Account(
                id: "testAccountId",
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: nil,
                isPremium: true
            ))
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(),
                houseworkManager: .init(houseworkClient: .previewValue),
                houseworkClient: .init(syncRetentionHandler: {
                    #expect($0 == inputCohabitantId)
                    confirmation()
                }),
                retentionSyncStateStore: makeSyncStateStore(#function)
            )
            // グループ未参加の状態では同期先が無いためスキップされる
            await useCase.syncHouseworkRetentionIfNeeded()
            try? await accountStore.registerCohabitantId(inputCohabitantId)

            await useCase.syncHouseworkRetentionIfNeeded()
        }
    }

    @Test("保持期限の同期に失敗した場合は次の機会に再試行される")
    func syncHouseworkRetentionRetriesAfterFailure() async {
        await confirmation(expectedCount: 2) { confirmation in
            let accountStore = AccountStore(account: Account(
                id: "testAccountId",
                userName: "testUserName",
                fcmToken: nil,
                cohabitantId: "cohabitantId",
                isPremium: true
            ))
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(),
                houseworkManager: .init(houseworkClient: .previewValue),
                houseworkClient: .init(syncRetentionHandler: { _ in
                    confirmation()
                    throw DomainError.other
                }),
                retentionSyncStateStore: makeSyncStateStore(#function)
            )
            await useCase.syncHouseworkRetentionIfNeeded()

            await useCase.syncHouseworkRetentionIfNeeded()
        }
    }

}
