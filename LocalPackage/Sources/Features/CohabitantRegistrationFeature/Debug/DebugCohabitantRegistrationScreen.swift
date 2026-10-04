//
//  DebugCohabitantRegistrationScreen.swift
//  LocalPackage
//

#if DEBUG

import HometeDomain
import SwiftUI

/// 登録済みのアカウントでもP2P登録フローを通しで確認するためのデバッグ画面
///
/// 複数台でこの画面を開くと、実際のP2P通信で役割決め・招待トークンの共有・完了の待ち合わせまでを行う。
/// サーバーへの書き込み（招待トークンの発行・グループへの参加）だけをモックに差し替えるため、
/// すでに同居人グループに所属している端末でも、実データを壊さずに完走できるかを確認できる。
public struct DebugCohabitantRegistrationScreen: View {

    @Environment(\.loginContext.account) var account

    public init() {}

    public var body: some View {
        CohabitantRegistrationView()
            // サーバーへの書き込み・Analyticsの送信を実環境に飛ばさないため、
            // 依存をまるごとpreviewValueにした上で、書き込みを握り潰すモックだけ差し込む
            .environment(\.appDependencies, .init(cohabitantInvitationClient: .debugMock(account: account)))
            .environment(AccountStore(accountInfoClient: .debugMock(account: account), account: account))
    }

}

private extension CohabitantInvitationClient {

    /// 招待の発行・グループへの参加を、サーバーへ書き込まずに成功させるClient
    /// - Parameter account: 参加先として返すグループIDを持つ自分のアカウント
    static func debugMock(account: Account) -> Self {
        .init(
            issue: { .init(token: "debug-token", cohabitantId: account.cohabitantId, expiresAt: .now) },
            join: { _ in .init(cohabitantId: account.cohabitantId ?? "debug-cohabitant", isNewMember: true) }
        )
    }

}

private extension AccountInfoClient {

    /// アカウントを更新せずに成功させるClient
    /// - Parameter account: 画面入口のアカウント確認とリーダーの取り直し（`reload`）で返す自分のアカウント
    static func debugMock(account: Account) -> Self {
        .init(
            insertOrUpdate: { _ in },
            fetch: { _ in account }
        )
    }

}

#endif
