//
//  LaunchStateStoreTest.swift
//  hometeTests
//

@testable import HometeDomain
import Testing

@MainActor
struct LaunchStateStoreTest {

    private let signedInAuth = AccountAuthInfo(
        result: AccountAuthResult(id: "testAccountId"),
        alreadyLoadedAtInitiate: true
    )
    private let signedOutAuth = AccountAuthInfo(result: nil, alreadyLoadedAtInitiate: true)
    private let anonymousAuth = AccountAuthInfo(
        result: AccountAuthResult(id: "testAccountId", isAnonymous: true),
        alreadyLoadedAtInitiate: true
    )

    private func makeAccount(id: String = "testAccountId", cohabitantId: String? = nil) -> Account {
        Account(id: id, userName: "testUserName", cohabitantId: cohabitantId)
    }

    private func makeStore(
        accountStore: AccountStore,
        houseworkClient: HouseworkClient = .previewValue,
        purchaseClient: PurchaseClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) -> LaunchStateStore {
        LaunchStateStore(
            accountStore: accountStore,
            authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: CohabitantStore(),
                subscriptionStore: SubscriptionStore(purchaseClient: purchaseClient),
                houseworkManager: .init(houseworkClient: houseworkClient)
            ),
            analyticsClient: analyticsClient
        )
    }

    @Test("サインイン済みでアカウントが取得できた場合はログイン済みになる")
    func syncAuthChangeLoggedIn() async {
        // Arrange

        let expectedAccount = makeAccount()
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in expectedAccount }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .loggedIn(context: LoginContext(account: expectedAccount)))
    }

    @Test("サインイン済みでアカウントが未登録の場合は会員登録画面になる")
    func syncAuthChangePreLoggedIn() async {
        // Arrange

        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in nil }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .preLoggedIn(auth: AccountAuthResult(id: "testAccountId")))
    }

    @Test("サインイン済みでアカウントの取得に失敗した場合は、会員登録画面に進まずサインアウトする")
    func syncAuthChangeAccountLoadFailure() async {
        await confirmation("Firebase Authからサインアウトする") { signedOut in
            // Arrange: App Checkの検証失敗などで、アカウントの有無を判定できない状況

            let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in throw DomainError.other }))
            let store = LaunchStateStore(
                accountStore: accountStore,
                authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase(
                    accountStore: accountStore,
                    cohabitantStore: CohabitantStore(),
                    subscriptionStore: SubscriptionStore(purchaseClient: .previewValue),
                    houseworkManager: .init(houseworkClient: .previewValue)
                ),
                accountAuthClient: .init(signOut: { signedOut() })
            )

            // Act

            store.syncAuthChange(signedInAuth)
            await store.waitForSync()

            // Assert

            #expect(store.launchState == .notLoggedIn)
        }
    }

    @Test("サインイン済みでアカウントの取得に失敗した場合は、取得に失敗したことを伝える")
    func syncAuthChangeAccountLoadFailureIsPublished() async {
        // Arrange: ログイン画面から入り直して失敗すると画面が切り替わらないため、失敗を別に伝える必要がある

        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in throw DomainError.noNetwork }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Assert

        #expect(store.accountLoadFailure == .noNetwork)
    }

    @Test("アカウントの取得失敗を受け取ったと伝えたら、失敗が消える")
    func clearAccountLoadFailure() async {
        // Arrange: 同じ失敗が続いても変化として届くよう、受け取った側が消す

        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in throw DomainError.other }))
        let store = makeStore(accountStore: accountStore)
        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Act

        store.clearAccountLoadFailure()

        // Assert

        #expect(store.accountLoadFailure == nil)
    }

    @Test("サインアウトの通知を受けたら未ログインになる")
    func syncAuthChangeNotLoggedIn() async {
        // Arrange

        let accountStore = AccountStore(account: makeAccount())
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedOutAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .notLoggedIn)
        #expect(accountStore.account == nil)
    }

    @Test("サインイン処理中にサインアウトが届いた場合、古い認証情報で会員登録画面に戻らない")
    func syncAuthChangeSignedOutDuringSignIn() async {
        // Arrange: ロードは成功するがアカウント未登録として扱われる状況にして、
        //          旧実装なら`.preLoggedIn`で`.notLoggedIn`を上書きする経路を通す
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in nil }))
        let store = makeStore(accountStore: accountStore)

        // Act: サインインの反映が終わる前にサインアウトが届いた状況を再現する

        store.syncAuthChange(signedInAuth)
        store.syncAuthChange(signedOutAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .notLoggedIn)
    }

    @Test("サインイン処理中にサインアウトが届いた場合、後片付けが最後に走ってアカウントが残らない")
    func syncAuthChangeCleansUpAfterStaleSignIn() async {
        // Arrange

        let loadedAccount = makeAccount()
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in loadedAccount }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedInAuth)
        store.syncAuthChange(signedOutAuth)
        await store.waitForSync()

        // Assert: 世代が直列化されていないと、後から再開したサインイン側がアカウントを書き戻す

        #expect(store.launchState == .notLoggedIn)
        #expect(accountStore.account == nil)
    }

    @Test("アカウント変更が積まれた状態でサインアウトが届いても、走っているサインイン反映が打ち切られる")
    func syncAuthChangeSignedOutCancelsRunningSignIn() async {
        // Arrange: `accountStore.load`が発火させるアカウント変更を待ち行列に積んだ上で、
        //          サインインの反映がawaitで止まっている状況を再現する
        let loadedAccount = makeAccount()
        let gate = TestGate()
        let accountInfoClient = AccountInfoClient(
            fetch: { _ in loadedAccount },
            addSnapshotListener: { _, _ in
                await gate.wait()
                return .init { $0.finish() }
            }
        )
        let accountStore = AccountStore(accountInfoClient: accountInfoClient)
        let purchaseClient = PurchaseClient(logIn: { _ in
            // 打ち切られた世代が、権限を失ったアカウントに課金情報を紐付けてはいけない
            Issue.record()
        })
        let store = makeStore(accountStore: accountStore, purchaseClient: purchaseClient)

        // Act

        store.syncAuthChange(signedInAuth)
        await gate.waitUntilArrived()
        store.syncAccountChange(loadedAccount)
        store.syncAuthChange(signedOutAuth)
        gate.open()
        await store.waitForSync()

        // Assert: 待ち行列の末尾だけを打ち切ると、走っているサインインにキャンセルが届かない

        #expect(store.launchState == .notLoggedIn)
        #expect(accountStore.account == nil)
    }

    @Test("サインイン反映中に届いたアカウント変更で、反映が打ち切られてログイン済みに進めなくならない")
    func syncAccountChangeDuringSignInDoesNotAbortSignIn() async {
        // Arrange: `accountStore.load`がアカウントを書いた結果として
        //          `RootView`の`onChange(of: account)`が発火する状況を再現する
        let expectedAccount = makeAccount()
        let gate = TestGate()
        let accountInfoClient = AccountInfoClient(
            fetch: { _ in expectedAccount },
            addSnapshotListener: { _, _ in
                await gate.wait()
                return .init { $0.finish() }
            }
        )
        let accountStore = AccountStore(accountInfoClient: accountInfoClient)
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(signedInAuth)
        await gate.waitUntilArrived()
        store.syncAccountChange(expectedAccount)
        gate.open()
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .loggedIn(context: LoginContext(account: expectedAccount)))
        #expect(accountStore.account == expectedAccount)
    }

    @Test("未ログイン中にアカウント情報が変化しても、ログイン済みには遷移しない")
    func syncAccountChangeWhileNotLoggedIn() async {
        // Arrange

        let accountStore = AccountStore()
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAccountChange(makeAccount())
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .launching)
    }

    @Test("ログイン済みでアカウント情報が変化したら、新しいアカウントで反映される")
    func syncAccountChangeWhileLoggedIn() async {
        // Arrange

        let updatedAccount = makeAccount(cohabitantId: "cohabitantId")
        let accountStore = AccountStore(account: updatedAccount)
        let store = makeStore(accountStore: accountStore)
        store.update(.loggedIn(context: LoginContext(account: makeAccount())))

        // Act

        store.syncAccountChange(updatedAccount)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .loggedIn(context: LoginContext(account: updatedAccount)))
    }

    @Test("受け取ったFCMトークンは、ログイン後にアカウントへ紐づけて保存される")
    func receiveFcmTokenIsAppliedOnSignIn() async {
        await confirmation("ログインしたアカウントのFCMトークンとして保存される") { confirmation in
            // Arrange

            let inputFcmToken = "testFcmToken"
            let loadedAccount = makeAccount()
            let accountInfoClient = AccountInfoClient(
                fetch: { _ in loadedAccount },
                updateFcmToken: { accountId, fcmToken in
                    #expect((accountId, fcmToken) == (loadedAccount.id, inputFcmToken))
                    confirmation()
                }
            )
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let store = makeStore(accountStore: accountStore)
            store.receive(fcmToken: inputFcmToken)

            // Act

            store.syncAuthChange(signedInAuth)
            await store.waitForSync()
        }
    }

    @Test("匿名でグループに参加済みなら、Apple連携を求める状態になる")
    func syncAuthChangeAnonymousWithCohabitant() async {
        // Arrange

        let loadedAccount = makeAccount(cohabitantId: "cohabitantId")
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in loadedAccount }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(anonymousAuth)
        await store.waitForSync()

        // Assert

        let expected = LaunchState.accountLinkRequired(context: LoginContext(account: loadedAccount, isAnonymous: true))
        #expect(store.launchState == expected)
    }

    @Test("匿名でグループに未参加なら、匿名のままログイン済みになる")
    func syncAuthChangeAnonymousWithoutCohabitant() async {
        // Arrange

        let loadedAccount = makeAccount()
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in loadedAccount }))
        let store = makeStore(accountStore: accountStore)

        // Act

        store.syncAuthChange(anonymousAuth)
        await store.waitForSync()

        // Assert

        let expected = LaunchState.loggedIn(context: LoginContext(account: loadedAccount, isAnonymous: true))
        #expect(store.launchState == expected)
    }

    @Test("匿名で未参加の間に相手が参加してグループに入ったら、Apple連携を求める状態に切り替わる")
    func syncAccountChangeAnonymousJoinedCohabitant() async {
        // Arrange

        let notJoinedAccount = makeAccount()
        let joinedAccount = makeAccount(cohabitantId: "cohabitantId")
        let fetchCount = TestCounter()
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in
            await fetchCount.increment()
            return await fetchCount.value == 1 ? notJoinedAccount : joinedAccount
        }))
        let store = makeStore(accountStore: accountStore)
        store.syncAuthChange(anonymousAuth)
        await store.waitForSync()
        // 相手の参加は、購読しているアカウントの更新としてAccountStoreに先に届く
        _ = try? await accountStore.load(.init(id: joinedAccount.id))

        // Act

        store.syncAccountChange(joinedAccount)
        await store.waitForSync()

        // Assert

        let expected = LaunchState.accountLinkRequired(context: LoginContext(account: joinedAccount, isAnonymous: true))
        #expect(store.launchState == expected)
    }

    @Test("Apple連携を求めている間に連携を終えたら、ログイン済みになる")
    func syncAuthChangeLinkedWhileAccountLinkRequired() async {
        // Arrange

        let loadedAccount = makeAccount(cohabitantId: "cohabitantId")
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in loadedAccount }))
        let store = makeStore(accountStore: accountStore)
        store.syncAuthChange(anonymousAuth)
        await store.waitForSync()

        // Act

        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .loggedIn(context: LoginContext(account: loadedAccount)))
    }

    @Test("オンボーディング中にApple連携を終えたら、ログイン済みに進まず匿名でなくなった認証で会員登録画面のままになる")
    func syncAuthChangeLinkedWhilePreLoggedIn() async {
        // Arrange: 匿名で始めて会員登録画面に入り、アカウントを登録した後

        let registeredAccount = makeAccount()
        let fetchCalls = TestLockedArray<Void>()
        let accountStore = AccountStore(accountInfoClient: .init(fetch: { _ in
            await fetchCalls.append(())
            // 1回目（匿名で始めた直後）は未登録、2回目（連携の後）は登録済み
            return await fetchCalls.values.count == 1 ? nil : registeredAccount
        }))
        let store = makeStore(accountStore: accountStore)
        store.syncAuthChange(anonymousAuth)
        await store.waitForSync()

        // Act

        store.syncAuthChange(signedInAuth)
        await store.waitForSync()

        // Assert

        #expect(store.launchState == .preLoggedIn(auth: AccountAuthResult(id: "testAccountId", isAnonymous: false)))
    }

    @Test("サインアウトを挟まずに別のユーザーへ切り替わったら、前のユーザーの購読を止めてから切り替え先を購読する")
    func syncAuthChangeUserSwitched() async {
        let anonymousAccount = makeAccount()
        let existingAccount = makeAccount(id: "existingAccountId")
        let existingAuth = AccountAuthInfo(
            result: AccountAuthResult(id: "existingAccountId"),
            alreadyLoadedAtInitiate: true
        )

        await confirmation(expectedCount: 1) { removed in
            // Arrange

            let accountStore = AccountStore(
                accountInfoClient: .init(
                    fetch: { accountId in
                        accountId == "existingAccountId" ? existingAccount : anonymousAccount
                    },
                    addSnapshotListener: { _, _ in .makeStream().stream },
                    removeSnapshotListener: { _ in removed() }
                )
            )
            let store = makeStore(accountStore: accountStore)
            store.syncAuthChange(anonymousAuth)
            await store.waitForSync()

            // Act

            store.syncAuthChange(existingAuth)
            await store.waitForSync()

            // Assert

            #expect(store.launchState == .loggedIn(context: LoginContext(account: existingAccount)))
        }
    }

}
