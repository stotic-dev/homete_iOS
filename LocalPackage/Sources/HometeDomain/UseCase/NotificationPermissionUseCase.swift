//
//  NotificationPermissionUseCase.swift
//  LocalPackage
//

/// プッシュ通知の権限リクエストと、オンボーディングでの案内状況を管理するUseCase
/// - Note: 案内済みかどうかは`NotificationGuideStateClient`で永続化する。オンボーディングで「あとで設定する」を
///         選んだユーザーに対し、その後の起動でも勝手にダイアログを出さないようにするため
public final class NotificationPermissionUseCase: Sendable {

    private let notificationPermissionClient: NotificationPermissionClient
    private let notificationGuideStateClient: NotificationGuideStateClient

    public init(
        notificationPermissionClient: NotificationPermissionClient,
        notificationGuideStateClient: NotificationGuideStateClient
    ) {
        self.notificationPermissionClient = notificationPermissionClient
        self.notificationGuideStateClient = notificationGuideStateClient
    }

    /// オンボーディングの案内画面から権限をリクエストする
    /// - Returns: 権限が許可されているかどうか
    @discardableResult
    public func requestOnOnboarding() async -> Bool {
        await notificationGuideStateClient.saveHasGuidedOnOnboarding(true)
        return await request()
    }

    /// オンボーディングの案内画面で権限リクエストがスキップされたことを記録する
    public func skipOnOnboarding() async {
        await notificationGuideStateClient.saveHasGuidedOnOnboarding(true)
    }

    /// オンボーディングで案内していない場合に限り、権限をリクエストする
    /// - Note: ホーム着地のたびに呼ばれる想定。一度でも案内していれば、その判断を尊重してリクエストしない
    public func requestIfNeeded() async {
        let hasGuided = await notificationGuideStateClient.loadHasGuidedOnOnboarding()
        guard !hasGuided else { return }

        await request()
    }

}

private extension NotificationPermissionUseCase {

    /// プッシュ通知の権限をリクエストし、許可された場合はAPNsへのデバイス登録まで行う
    /// - Returns: 権限が許可されているかどうか
    /// - Note: OSの仕様上、権限が決定済みの場合はダイアログが出ないため、繰り返し呼び出しても問題ない
    @discardableResult
    func request() async -> Bool {
        let isGranted = await notificationPermissionClient.requestAuthorization()
        guard isGranted else { return false }

        await notificationPermissionClient.registerForRemoteNotifications()
        return true
    }

}
