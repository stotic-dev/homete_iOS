//
//  AuthSubscriptionSyncUseCase.swift
//  LocalPackage
//

@MainActor
public struct AuthSubscriptionSyncUseCase {

    private let accountStore: AccountStore
    private let cohabitantStore: CohabitantStore
    private let subscriptionStore: SubscriptionStore
    private let houseworkManager: HouseworkManager
    private let analyticsClient: AnalyticsClient
    private let sentInvitationStore: SentInvitationStore

    public init(
        accountStore: AccountStore,
        cohabitantStore: CohabitantStore,
        subscriptionStore: SubscriptionStore,
        houseworkManager: HouseworkManager,
        analyticsClient: AnalyticsClient = .previewValue,
        sentInvitationStore: SentInvitationStore = .init()
    ) {
        self.accountStore = accountStore
        self.cohabitantStore = cohabitantStore
        self.subscriptionStore = subscriptionStore
        self.houseworkManager = houseworkManager
        self.analyticsClient = analyticsClient
        self.sentInvitationStore = sentInvitationStore
    }

    /// サインイン成功時にアカウント情報をロードし、サブスクリプション状態を同期する
    ///
    /// トークン失効による自動サインアウトはFirebase Auth側の判断で非同期に起きるため、
    /// このメソッドの実行中に認証状態が変わりうる。その場合は`LaunchStateStore`が
    /// この世代のTaskをキャンセルするので、**awaitを挟むたびにキャンセルを確認して打ち切る**。
    /// 確認を省くと、無効になったユーザーIDで購読を張ったり課金情報を紐付けたりしてしまう。
    /// - Returns: ロードに成功したアカウント（アカウント未登録、または途中で打ち切った場合はnil）
    /// - Throws: アカウントの取得に失敗した場合。未登録（nil）とは区別する
    public func syncOnSignedIn(_ authResult: AccountAuthResult) async throws -> Account? {
        guard let account = try await accountStore.load(authResult) else { return nil }
        // ロードした内容は無効なユーザーのものなので、キャッシュごと破棄する
        guard !Task.isCancelled else {
            accountStore.clear()
            return nil
        }

        await accountStore.startObservingIfNeeded(account.id)
        guard !Task.isCancelled else { return nil }

        await subscriptionStore.logIn(account.id)
        guard !Task.isCancelled else { return nil }

        return accountStore.account ?? account
    }

    /// サインアウト時にFirestoreの購読を止め、アカウント情報とサブスクリプション状態、
    /// ユーザーに紐づく計測情報をクリアする
    /// - Note: `is_premium`は`SubscriptionStore.logOut()`が`false`を送る。
    ///         匿名ユーザーにエンタイトルメントは無く「未加入」が実態のため、削除ではなく値の更新にしている
    public func syncOnSignedOut() async {
        await clearSession()
        analyticsClient.setUserProperty(.cleared(.hasCohabitant))
        analyticsClient.setUserProperty(.cleared(.cohabitantMemberCount))
        analyticsClient.setUserProperty(.cleared(.isAnonymous))
        analyticsClient.clearId()
    }

    /// サインアウトを挟まずに別のユーザーへ切り替わったとき、前のユーザーの購読とキャッシュを片付ける
    /// - Note: 計測のユーザーIDは切り替え先で設定済みのため消さない。ユーザープロパティはログイン後に設定し直される
    public func syncOnUserSwitched() async {
        await clearSession()
    }

    /// アカウント新規登録時にアカウントを登録し、サブスクリプションにログインする
    public func syncOnRegistered(auth: AccountAuthResult, userName: UserName) async throws -> Account {
        let account = try await accountStore.registerAccount(auth: auth, userName: userName)
        await accountStore.startObservingIfNeeded(account.id)
        await subscriptionStore.logIn(account.id)
        return accountStore.account ?? account
    }

}

private extension AuthSubscriptionSyncUseCase {

    /// Firestoreの購読を止め、アカウント情報とサブスクリプション状態をクリアする
    func clearSession() async {
        // 購読を残すと、権限を失ったユーザーID・グループIDのままFirestoreへのアクセスが続く
        await accountStore.stopObserving()
        accountStore.clear()
        await cohabitantStore.clear()
        await houseworkManager.clearOnSignedOut()
        await subscriptionStore.logOut()
        // 次にログインした人の未参加ホームに、前のアカウントが送った招待を出さない
        await sentInvitationStore.clear()
    }

}
