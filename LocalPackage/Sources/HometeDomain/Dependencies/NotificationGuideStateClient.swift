//
//  NotificationGuideStateClient.swift
//  LocalPackage
//

/// オンボーディングでプッシュ通知の案内を行ったかどうかを永続化するClient
/// - Note: OSの権限状態とは別に、アプリ側が「一度案内したかどうか」を覚えておくために使う。
///         権限が未決定のままスキップされたケースを、次回起動以降も区別できるようにするのが目的
public struct NotificationGuideStateClient: Sendable {

    /// オンボーディングで通知の案内を行ったかどうかを読み出す
    public let loadHasGuidedOnOnboarding: @Sendable () async -> Bool
    /// オンボーディングで通知の案内を行ったことを記録する
    public let saveHasGuidedOnOnboarding: @Sendable (Bool) async -> Void

    public init(
        loadHasGuidedOnOnboarding: @Sendable @escaping () async -> Bool = { false },
        saveHasGuidedOnOnboarding: @Sendable @escaping (Bool) async -> Void = { _ in }
    ) {
        self.loadHasGuidedOnOnboarding = loadHasGuidedOnOnboarding
        self.saveHasGuidedOnOnboarding = saveHasGuidedOnOnboarding
    }

}

public extension NotificationGuideStateClient {

    static let previewValue: NotificationGuideStateClient = .init()

}
