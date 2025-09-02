//
//  LaunchState.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/02.
//

enum LaunchState: Equatable {
    
    /// 起動中
    case launching
    /// ログイン済み
    case loggedIn(AccountAuthResult)
    /// 未ログイン
    case notLoggedIn
    
    func next(_ authInfo: AccountAuthResult?) -> Self {
        
        guard let authInfo else { return .notLoggedIn }
        return .loggedIn(authInfo)
    }
}
