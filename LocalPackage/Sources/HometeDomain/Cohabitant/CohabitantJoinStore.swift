//
//  CohabitantJoinStore.swift
//  LocalPackage
//

import Observation

/// 招待リンクからグループへ参加する処理を扱うStore
@MainActor
@Observable
public final class CohabitantJoinStore {

    public private(set) var state: CohabitantJoinState = .confirming

    private let token: String

    // MARK: Dependencies

    private let cohabitantInvitationClient: CohabitantInvitationClient
    private let analyticsClient: AnalyticsClient
    private let accountStore: AccountStore

    public init(
        token: String,
        cohabitantInvitationClient: CohabitantInvitationClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        accountStore: AccountStore = .init()
    ) {
        self.token = token
        self.cohabitantInvitationClient = cohabitantInvitationClient
        self.analyticsClient = analyticsClient
        self.accountStore = accountStore
    }

    /// 招待トークンを使ってグループに参加する
    public func join() async {
        state = .processing
        analyticsClient.log(.cohabitantRegistration(.started(method: .link)))

        do {
            let result = try await cohabitantInvitationClient.join(token)
            // サーバ側でアカウントの更新まで済んでいるため、オンメモリの状態だけ揃える
            accountStore.applyCohabitantId(result.cohabitantId)

            guard result.isNewMember else {
                // 自分のグループのリンクを開いただけなので、登録の完了としては数えない
                state = .alreadyMember
                analyticsClient.log(.cohabitantInvitation(.joinAlreadyMember))
                return
            }

            state = .completed
            analyticsClient.log(.cohabitantInvitation(.joinSucceeded))
            analyticsClient.log(.cohabitantRegistration(.completed(method: .link, isSuccess: true)))
        } catch {
            let failure = CohabitantJoinFailure(error)
            state = .failed(failure)
            analyticsClient.log(.cohabitantInvitation(.joinFailed(failure)))
            analyticsClient.log(.cohabitantRegistration(.completed(method: .link, isSuccess: false)))
        }
    }

}
