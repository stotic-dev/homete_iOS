//
//  NotificationPermissionUseCase.swift
//  LocalPackage
//

/// プッシュ通知の権限リクエストと、オンボーディングでの案内状況を管理するUseCase
/// - Note: 案内済みかどうかはアプリ起動中のみ保持する。オンボーディングで「あとで設定する」を選んだ直後に
///         ホームで再びダイアログが出るのを防ぎつつ、次回起動以降は改めて案内できるようにするため
public actor NotificationPermissionUseCase {

    private let notificationPermissionClient: NotificationPermissionClient

    /// この起動中にオンボーディングで通知の案内を行ったかどうか
    private var hasGuidedOnOnboarding = false

    public init(notificationPermissionClient: NotificationPermissionClient) {
        self.notificationPermissionClient = notificationPermissionClient
    }

    /// オンボーディングの案内画面から権限をリクエストする
    /// - Returns: 権限が許可されているかどうか
    @discardableResult
    public func requestOnOnboarding() async -> Bool {
        hasGuidedOnOnboarding = true
        return await request()
    }

    /// オンボーディングの案内画面で権限リクエストがスキップされたことを記録する
    public func skipOnOnboarding() {
        hasGuidedOnOnboarding = true
    }

    /// オンボーディングで案内していない場合に限り、権限をリクエストする
    /// - Note: ホーム着地のたびに呼ばれる想定。ユーザーが直前に案内をスキップしたときは、その判断を尊重してリクエストしない
    public func requestIfNeeded() async {
        guard !hasGuidedOnOnboarding else { return }
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
