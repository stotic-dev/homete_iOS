//
//  AuthSubscriptionSyncUseCase.swift
//  LocalPackage
//

@MainActor
public struct AuthSubscriptionSyncUseCase {

    private let accountStore: AccountStore
    private let subscriptionStore: SubscriptionStore

    public init(accountStore: AccountStore, subscriptionStore: SubscriptionStore) {
        self.accountStore = accountStore
        self.subscriptionStore = subscriptionStore
    }

    /// サインイン成功時にアカウント情報をロードし、サブスクリプション状態を同期する
    /// - Returns: ロードに成功したアカウント（アカウント未登録の場合はnil）
    public func syncOnSignedIn(_ authResult: AccountAuthResult) async -> Account? {
        guard let account = await accountStore.load(authResult) else { return nil }
        await subscriptionStore.logIn(account.id)
        return account
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
        return account
    }

}
