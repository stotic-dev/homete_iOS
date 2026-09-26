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
/// そこで反映処理をキューに積み、**このStoreが1本ずつ順番に走らせる**ことで直列化している。
/// 加えて認証が切り替わったときだけ、走っている世代を打ち切ってから最新の認証を積み直す。これにより
///
/// - 最後に届いた変化が必ず勝つ
/// - サインアウトの後片付け（`syncOnSignedOut`）が必ず最後に走る
///
/// という不変条件が成立し、古い認証情報で画面を進めたりFirestoreを読み書きしたりしなくなる。
///
/// 打ち切りを認証の変化に限るのは、アカウント情報の変化が反映処理自身の副作用として届くため。
/// これで打ち切ると自分の世代をキャンセルし、`LaunchState`を誰も更新しないまま起動画面で止まる。
@MainActor
@Observable
public final class LaunchStateStore {

    public private(set) var launchState: LaunchState

    /// 未着手の世代。認証が切り替わったときは捨てて、最新の認証だけを積み直す
    @ObservationIgnored private var pendingKinds: [SyncKind] = []
    /// 走っている世代。認証が切り替わったときに打ち切る対象
    @ObservationIgnored private var runningTask: Task<Void, Never>?
    /// 積まれた世代を順番に走らせるTask。走らせている間だけ保持する
    @ObservationIgnored private var drainTask: Task<Void, Never>?
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
        // 認証が切り替わると、走っている反映も未着手の反映も無効な認証情報を握っているため、打ち切る
        enqueue(.auth(auth), invalidatesPrevious: true)
    }

    /// アカウント情報の変化を反映する
    /// - Parameter account: 変化を検知した時点のアカウント情報
    /// - Note: 進行中の世代は打ち切らない。アカウントの変化は反映処理自身（アカウントのロード・
    ///         FCMトークンの更新・プレミアム状態の反映）が起こすため、打ち切ると自分の世代を
    ///         キャンセルして`LaunchState`を更新できなくなる
    public func syncAccountChange(_ account: Account?) {
        enqueue(.account(account), invalidatesPrevious: false)
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

    /// 積まれた反映処理がすべて終わるのを待つ
    /// - Note: 世代の直列化を検証するためにテストから使う
    func waitForSync() async {
        await drainTask?.value
    }

}

// MARK: - 世代管理

private extension LaunchStateStore {

    enum SyncKind {

        case auth(AccountAuthInfo)
        case account(Account?)

    }

    /// 世代を積み、1本ずつ順番に走らせる
    /// - Parameter invalidatesPrevious: 走っている世代と未着手の世代を打ち切るかどうか。
    ///   打ち切った世代は`LaunchState`を更新せずに終わるため、
    ///   **代わりに画面を進める世代を必ず積むイベントでのみ`true`にする**
    func enqueue(_ kind: SyncKind, invalidatesPrevious: Bool) {
        if invalidatesPrevious {
            // 未着手の世代はこの後に積む最新の認証で必ず上書きされるため、走らせずに捨てる
            pendingKinds.removeAll()
            runningTask?.cancel()
        }
        pendingKinds.append(kind)
        startDrainIfNeeded()
    }

    func startDrainIfNeeded() {
        guard drainTask == nil else { return }
        drainTask = Task {
            await self.drain()
        }
    }

    /// 積まれた世代を、前の世代の完了を待ちながら順番に走らせる
    ///
    /// 待ち合わせるTask（このメソッドを走らせているTask）と1世代分の処理のTask（`runningTask`）を
    /// 分けているのは、`Task.value`の待ち合わせにキャンセルが伝播しないため。ひとつのTaskに
    /// 「前の世代を待ってから自分の処理を走らせる」と書くと、キャンセルは待っている世代にしか届かず、
    /// **走っている世代は打ち切られないまま古い認証情報で`LaunchState`やストアを書き換えてしまう。**
    ///
    /// また、キャンセルは協調的なので`cancel()`だけでは打ち切った世代が後から再開して状態を
    /// 上書きしうる。打ち切った世代の完了も待つことで、後片付けが必ず最後に走る順序を保証する。
    func drain() async {
        while !pendingKinds.isEmpty {
            let kind = pendingKinds.removeFirst()
            let task = Task {
                await self.apply(kind)
            }
            runningTask = task
            await task.value
            runningTask = nil
        }
        drainTask = nil
    }

    func apply(_ kind: SyncKind) async {
        switch kind {
        case let .auth(auth):
            await applyAuthChange(auth)

        case let .account(account):
            await applyAccountChange(account)
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
        // 認証が切り替わって打ち切られた世代は、古いアカウントで先に進めない
        guard !Task.isCancelled,
              launchState.isLoggedIn,
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
