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
    /// 未ログイン
    case notLoggedIn

    public var isLoggedIn: Bool {

        if case .loggedIn = self { return true }
        return false
    }
}
