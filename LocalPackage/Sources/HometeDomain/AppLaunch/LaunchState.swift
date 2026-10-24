//
//  LaunchState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/02.
//

public enum LaunchState: Equatable {

    /// 起動中
    case launching
    /// 仮ログイン（アカウント未作成）
    case preLoggedIn(auth: AccountAuthResult)
    /// ログイン済み
    case loggedIn(context: LoginContext)
    /// 匿名のままグループに参加している。Appleアカウントと連携するまで先に進ませない
    case accountLinkRequired(context: LoginContext)
    /// 未ログイン
    case notLoggedIn

    /// ログインを終えてアプリに入るときの状態
    /// - Note: 匿名のままグループに参加していたら、Apple連携を終えるまでホームに入れない
    public static func entered(_ context: LoginContext) -> LaunchState {
        context.requiresAccountLink
            ? .accountLinkRequired(context: context)
            : .loggedIn(context: context)
    }

    public var isLoggedIn: Bool {
        if case .loggedIn = self { return true }
        return false
    }

    /// アカウントを読み込み済みの状態か
    /// - Note: Apple連携を求めている間も、アカウントの変化（グループからの脱退など）は反映し続ける
    var hasLoadedAccount: Bool {
        switch self {
        case .loggedIn, .accountLinkRequired:
            true

        case .launching, .preLoggedIn, .notLoggedIn:
            false
        }
    }

}
