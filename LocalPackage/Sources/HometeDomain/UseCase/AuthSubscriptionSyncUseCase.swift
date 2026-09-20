//
//  AuthSubscriptionSyncUseCase.swift
//  LocalPackage
//

@MainActor
public struct AuthSubscriptionSyncUseCase {

    private let accountStore: AccountStore
    private let subscriptionStore: SubscriptionStore
    private let houseworkClient: HouseworkClient
    private let analyticsClient: AnalyticsClient
    private let retentionSyncStateStore: HouseworkRetentionSyncStateStore

    public init(
        accountStore: AccountStore,
        subscriptionStore: SubscriptionStore,
        houseworkClient: HouseworkClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue
    ) {
        self.init(
            accountStore: accountStore,
            subscriptionStore: subscriptionStore,
            houseworkClient: houseworkClient,
            analyticsClient: analyticsClient,
            retentionSyncStateStore: .init()
        )
    }

    init(
        accountStore: AccountStore,
        subscriptionStore: SubscriptionStore,
        houseworkClient: HouseworkClient,
        analyticsClient: AnalyticsClient = .previewValue,
        retentionSyncStateStore: HouseworkRetentionSyncStateStore
    ) {
        self.accountStore = accountStore
        self.subscriptionStore = subscriptionStore
        self.houseworkClient = houseworkClient
        self.analyticsClient = analyticsClient
        self.retentionSyncStateStore = retentionSyncStateStore
    }

    /// サインイン成功時にアカウント情報をロードし、サブスクリプション状態を同期する
    /// - Returns: ロードに成功したアカウント（アカウント未登録の場合はnil）
    public func syncOnSignedIn(_ authResult: AccountAuthResult) async -> Account? {
        guard let account = await accountStore.load(authResult) else { return nil }
        await accountStore.startObservingIfNeeded(account.id)
        await subscriptionStore.logIn(account.id)
        // アプリ未起動の間に失効しているケースは状態変化として検知できないため、サインイン時にも突き合わせる
        await syncPremiumStateIfNeeded()
        return accountStore.account ?? account
    }

    /// サインアウト時にアカウント情報とサブスクリプション状態、ユーザーに紐づく計測情報をクリアする
    /// - Note: `is_premium`は`SubscriptionStore.logOut()`が`false`を送る。
    ///         匿名ユーザーにエンタイトルメントは無く「未加入」が実態のため、削除ではなく値の更新にしている
    public func syncOnSignedOut() async {
        await accountStore.stopObserving()
        accountStore.clear()
        await subscriptionStore.logOut()
        analyticsClient.setUserProperty(.cleared(.hasCohabitant))
        analyticsClient.setUserProperty(.cleared(.cohabitantMemberCount))
        analyticsClient.clearId()
    }

    /// アカウント新規登録時にアカウントを登録し、サブスクリプション状態を同期する
    public func syncOnRegistered(auth: AccountAuthResult, userName: UserName) async throws -> Account {
        let account = try await accountStore.registerAccount(auth: auth, userName: userName)
        await accountStore.startObservingIfNeeded(account.id)
        await subscriptionStore.logIn(account.id)
        await syncPremiumStateIfNeeded()
        return accountStore.account ?? account
    }

    /// プレミアム加入状態の変化をアカウントに反映し、家事データの保持期限を再計算させる
    public func syncPremiumStateIfNeeded() async {
        await accountStore.updateIsPremiumIfNeeded(subscriptionStore.isPremium)
        await syncHouseworkRetentionIfNeeded()
    }

    /// 家事データの保持期限をグループの現在のプランに合わせて再計算させる
    ///
    /// 保持期限の再計算はグループ全体に対する一括更新になるため、同期済みの内容と一致する場合は何もしない。
    /// 完了状態は`Account.isPremium`とは独立して永続化しており、グループ未参加のまま加入した場合や
    /// Functionの呼び出しに失敗した場合は記録を残さないことで、次の機会に必ずやり直す。
    public func syncHouseworkRetentionIfNeeded() async {
        guard let account = accountStore.account,
              let cohabitantId = account.cohabitantId else { return }

        let state = HouseworkRetentionSyncState(cohabitantId: cohabitantId, isPremium: account.isPremium)
        guard retentionSyncStateStore.load() != state else { return }

        do {
            try await houseworkClient.syncRetention(cohabitantId)
            retentionSyncStateStore.save(state)
        } catch {
            print("failed to sync housework retention: \(error)")
        }
    }

}
