//
//  LaunchStateStore.swift
//  LocalPackage
//

import Observation

/// 認証状態・アカウント情報の変化を`LaunchState`へ反映する
///
/// 反映処理はFirestoreやサブスクリプションへのアクセスでawaitを挟むため、複数の変化が
/// 同時に走ると完了順が入れ替わる。特にトークン失効による自動サインアウトはFirebase Auth側の
/// 判断で非同期に起きるので、サインイン処理の途中に割り込む。
///
/// そこで反映処理のTaskをこのStoreが1本だけ保持し、新しい変化が来たら
/// **前の世代をキャンセルしてから完了を待つ**ことで直列化している。これにより
///
/// - 最後に届いた変化が必ず勝つ
/// - サインアウトの後片付け（`syncOnSignedOut`）が必ず最後に走る
///
/// という不変条件が成立し、古い認証情報で画面を進めたりFirestoreを読み書きしたりしなくなる。
@MainActor
@Observable
public final class LaunchStateStore {

    public private(set) var launchState: LaunchState

    /// 反映処理の世代。1本だけ保持し、次の世代が前の世代の完了を待つ
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    /// 受け取り済みでアカウントへ未反映のFCMトークン
    @ObservationIgnored private var fcmToken: String?

    private let accountStore: AccountStore
    private let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase
    private let analyticsClient: AnalyticsClient

    public init(
        accountStore: AccountStore,
        authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase,
        analyticsClient: AnalyticsClient = .previewValue,
        launchState: LaunchState = .launching
    ) {
        self.accountStore = accountStore
        self.authSubscriptionSyncUseCase = authSubscriptionSyncUseCase
        self.analyticsClient = analyticsClient
        self.launchState = launchState
    }

    /// 認証状態の変化を反映する
    /// - Parameter auth: 変化を検知した時点の認証状態。世代ごとにこのスナップショットだけを見る
    /// - Note: サインアウトの検知だけは前の世代の完了を待たずに画面へ反映する。
    ///         前の世代が詰まったときにログイン画面へ戻れなくならないようにするため
    public func syncAuthChange(_ auth: AccountAuthInfo) {
        if auth.result == nil {
            launchState = .notLoggedIn
        }
        enqueue(.auth(auth))
    }

    /// アカウント情報の変化を反映する
    /// - Parameter account: 変化を検知した時点のアカウント情報
    public func syncAccountChange(_ account: Account?) {
        enqueue(.account(account))
    }

    /// 受け取ったFCMトークンを退避する
    /// - Note: ログイン前にも届くため、アカウントへの反映はログイン後の世代で行う
    public func receive(fcmToken: String) {
        self.fcmToken = fcmToken
    }

    /// 画面側の操作で`LaunchState`を直接差し替える
    /// - Note: アカウント登録の完了のように、認証状態・アカウント情報の変化として
    ///         届かない遷移のために用意している
    public func update(_ launchState: LaunchState) {
        self.launchState = launchState
    }

    /// 進行中の反映処理の完了を待つ
    /// - Note: 世代の直列化を検証するためにテストから使う
    func waitForSync() async {
        await syncTask?.value
    }

}

// MARK: - 世代管理

private extension LaunchStateStore {

    enum SyncKind {

        case auth(AccountAuthInfo)
        case account(Account?)

    }

    /// 前の世代をキャンセルし、その完了を待ってから次の世代を走らせる
    ///
    /// キャンセルは協調的なので`cancel()`だけでは前の世代が後から再開して状態を上書きしうる。
    /// 完了を待ち合わせることで、後片付けが必ず最後に走る順序を保証する。
    func enqueue(_ kind: SyncKind) {
        let previous = syncTask
        previous?.cancel()
        syncTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }

            switch kind {
            case let .auth(auth):
                await applyAuthChange(auth)

            case let .account(account):
                await applyAccountChange(account)
            }
        }
    }

}

// MARK: - 反映処理

private extension LaunchStateStore {

    func applyAuthChange(_ auth: AccountAuthInfo) async {
        guard let authResult = auth.result else {
            launchState = .notLoggedIn
            await authSubscriptionSyncUseCase.syncOnSignedOut()
            return
        }

        guard let account = await authSubscriptionSyncUseCase.syncOnSignedIn(authResult) else {
            guard !Task.isCancelled else { return }
            launchState = .preLoggedIn(auth: authResult)
            return
        }

        await updateFcmTokenIfNeeded()
        guard !Task.isCancelled else { return }
        applyLoggedIn(accountStore.account ?? account)
    }

    func applyAccountChange(_ account: Account?) async {
        guard launchState.isLoggedIn,
              let account else { return }

        await updateFcmTokenIfNeeded()
        guard !Task.isCancelled else { return }
        applyLoggedIn(accountStore.account ?? account)
        // グループへの参加はアカウント更新として届くため、参加後の保持期限同期をここで拾う
        await authSubscriptionSyncUseCase.syncHouseworkRetentionIfNeeded()
    }

    func applyLoggedIn(_ account: Account) {
        let context = LoginContext(account: account)
        analyticsClient.setUserProperty(.hasCohabitant(context.hasCohabitant))
        launchState = .loggedIn(context: context)
    }

    func updateFcmTokenIfNeeded() async {
        guard let fcmToken else { return }
        await accountStore.updateFcmTokenIfNeeded(fcmToken)
        self.fcmToken = nil
    }

}
