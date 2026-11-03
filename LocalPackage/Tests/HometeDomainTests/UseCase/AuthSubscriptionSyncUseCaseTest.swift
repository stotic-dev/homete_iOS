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

}

extension AuthSubscriptionSyncUseCaseTest.SignedInCase {

    @Test("サインイン成功時にアカウントをロードし、エンタイトルメントがプレミアムでもアカウントのisPremiumは書き換えない")
    func syncOnSignedInSuccess() async throws {
        try await confirmation(expectedCount: 2) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let inputAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
                cohabitantId: nil
            )
            // isPremiumはサーバーだけが書くため、エンタイトルメントがプレミアムでもロードした値のまま
            let expectedAccount = inputAccount
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

            let actual = try await useCase.syncOnSignedIn(inputAuthResult)

            #expect(actual == expectedAccount)
            #expect(accountStore.account == expectedAccount)
            #expect(subscriptionStore.isPremium)
        }
    }

    @Test("サインイン成功時に自分のアカウントの購読を開始する")
    func syncOnSignedInStartsObservingAccount() async throws {
        try await confirmation(expectedCount: 1) { confirmation in
            let inputAuthResult = AccountAuthResult(id: "testAccountId")
            let inputAccount = Account(
                id: inputAuthResult.id,
                userName: "testUserName",
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

            _ = try await useCase.syncOnSignedIn(inputAuthResult)
        }
    }

    @Test("サインイン成功時にアカウントが取得できない場合はサブスクリプションにログインしない")
    func syncOnSignedInAccountNotFound() async throws {
        try await confirmation(expectedCount: 0) { confirmation in
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

            let actual = try await useCase.syncOnSignedIn(inputAuthResult)

            #expect(actual == nil)
        }
    }

    @Test("サインアウト後、次のサインインでアカウント取得に失敗した場合は前ユーザーの情報でサブスクリプションにログインしない")
    func syncOnSignedInAfterSignedOutWithFetchFailure() async {
        await confirmation(expectedCount: 0) { confirmation in
            let previousAccount = Account(
                id: "previousAccountId",
                userName: "previousUserName",
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

            await #expect(throws: DomainError.other) {
                try await useCase.syncOnSignedIn(newAuthResult)
            }

            #expect(accountStore.account == nil)
        }
    }

    @Test("アカウントのロード中に世代が打ち切られた場合は、購読を開始せずロード結果も破棄する")
    func syncOnSignedInAbortsWhenCancelledDuringLoad() async throws {
        try await confirmation("古いユーザーIDでは購読もサブスクリプションのログインも行わない", expectedCount: 0) { confirmation in
            let staleAuthResult = AccountAuthResult(id: "staleAccountId")
            let staleAccount = Account(
                id: staleAuthResult.id,
                userName: "staleUserName",
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
            let task = Task { try await useCase.syncOnSignedIn(staleAuthResult) }
            task.cancel()

            let actual = try await task.value

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
                    // Xcode 26系では、initのデフォルト引数のasyncクロージャが並列実行中にクラッシュするため明示的に渡す
                    houseworkClient: .init(
                        snapshotListenerHandler: { _, _, _, _ in .makeStream().stream },
                        removeListenerHandler: { _ in
                            removedHouseworkListener()
                        },
                        fetchItemsHandler: { _, _, _ in [.makeForTest(id: 1)] }
                    )
                )
                // 外す対象のリスナーを張っておく
                await houseworkManager.setupObserver(
                    currentTime: .previewDate(year: 2026, month: 8, day: 11),
                    cohabitantId: "cohabitantId",
                    calendar: .japanese,
                    storagePolicy: .free
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
                await confirmation("is_anonymousをクリアする") { clearedIsAnonymous in
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

                                case .cleared(.isAnonymous):
                                    clearedIsAnonymous()

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

    @Test("サインアウト時に、前のアカウントが送った招待を消す")
    func syncOnSignedOutClearsSentInvitation() async {
        await confirmation("端末に保存した招待を消す") { cleared in
            // Arrange

            let sentInvitationStore = SentInvitationStore(sentInvitationClient: .init(clear: {
                cleared()
            }))
            await sentInvitationStore.save(
                CohabitantInvitation(token: "token", cohabitantId: nil, expiresAt: .distantFuture),
                accountId: "previousAccountId"
            )
            let useCase = AuthSubscriptionSyncUseCase(
                accountStore: AccountStore(),
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(),
                houseworkManager: .init(houseworkClient: .previewValue),
                sentInvitationStore: sentInvitationStore
            )

            // Act

            await useCase.syncOnSignedOut()

            // Assert

            #expect(sentInvitationStore.sentInvitation == nil)
        }
    }

}
