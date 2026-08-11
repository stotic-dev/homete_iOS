//
//  AuthSubscriptionSyncUseCase.swift
//  LocalPackage
//

@MainActor
public struct AuthSubscriptionSyncUseCase {

    private let accountStore: AccountStore
    private let subscriptionStore: SubscriptionStore
    private let houseworkClient: HouseworkClient

    public init(
        accountStore: AccountStore,
        subscriptionStore: SubscriptionStore,
        houseworkClient: HouseworkClient = .previewValue
    ) {
        self.accountStore = accountStore
        self.subscriptionStore = subscriptionStore
        self.houseworkClient = houseworkClient
    }

    /// サインイン成功時にアカウント情報をロードし、サブスクリプション状態を同期する
    /// - Returns: ロードに成功したアカウント（アカウント未登録の場合はnil）
    public func syncOnSignedIn(_ authResult: AccountAuthResult) async -> Account? {
        guard let account = await accountStore.load(authResult) else { return nil }
        await subscriptionStore.logIn(account.id)
        // アプリ未起動の間に失効しているケースは状態変化として検知できないため、サインイン時にも突き合わせる
        await syncPremiumStateIfNeeded()
        return accountStore.account ?? account
    }

    /// サインアウト時にアカウント情報とサブスクリプション状態をクリアする
    public func syncOnSignedOut() async {
        accountStore.clear()
        await subscriptionStore.logOut()
    }

    /// アカウント新規登録時にアカウントを登録し、サブスクリプション状態を同期する
    public func syncOnRegistered(auth: AccountAuthResult, userName: UserName) async throws -> Account {
        let account = try await accountStore.registerAccount(auth: auth, userName: userName)
        await subscriptionStore.logIn(account.id)
        await syncPremiumStateIfNeeded()
        return accountStore.account ?? account
    }

    /// プレミアム加入状態の変化をアカウントに反映し、家事データの保持期限を再計算させる
    ///
    /// 保持期限の再計算はグループ全体に対する一括更新になるため、実際にプランが変わった時だけ実行する。
    public func syncPremiumStateIfNeeded() async {
        let isPremium = subscriptionStore.isPremium
        guard await accountStore.updateIsPremiumIfNeeded(isPremium) else { return }
        guard let cohabitantId = accountStore.account?.cohabitantId else { return }

        do {
            try await houseworkClient.syncRetention(cohabitantId)
        } catch {
            print("failed to sync housework retention: \(error)")
        }
    }

}
