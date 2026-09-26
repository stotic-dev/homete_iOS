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

    private func makeAccount(id: String = "testAccountId", cohabitantId: String? = nil) -> Account {
        Account(id: id, userName: "testUserName", fcmToken: nil, cohabitantId: cohabitantId)
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

    @Test("受け取ったFCMトークンは、ログイン後にアカウントへ反映される")
    func receiveFcmTokenIsAppliedOnSignIn() async {
        await confirmation("FCMトークン付きでアカウントが更新される") { confirmation in
            // Arrange

            let inputFcmToken = "testFcmToken"
            let loadedAccount = makeAccount()
            let accountInfoClient = AccountInfoClient(
                insertOrUpdate: { account in
                    #expect(account.fcmToken == inputFcmToken)
                    confirmation()
                },
                fetch: { _ in loadedAccount }
            )
            let accountStore = AccountStore(accountInfoClient: accountInfoClient)
            let store = makeStore(accountStore: accountStore)
            store.receive(fcmToken: inputFcmToken)

            // Act

            store.syncAuthChange(signedInAuth)
            await store.waitForSync()
        }
    }

}
