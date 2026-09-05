//
//  PendingInvitationStore.swift
//  LocalPackage
//

import Observation

/// 未処理の招待トークンを保持するStore
///
/// Universal Linkはログイン前・アカウント登録前にも開かれるため、
/// 受け取ったトークンをここに退避し、ログイン完了後に画面側が消化する。
@MainActor
@Observable
public final class PendingInvitationStore {

    /// 参加処理待ちの招待トークン
    public private(set) var pendingToken: String?

    public init(pendingToken: String? = nil) {
        self.pendingToken = pendingToken
    }

    /// 招待トークンを保持する
    public func store(_ token: String) {
        pendingToken = token
    }

    /// 保持している招待トークンを破棄する
    public func clear() {
        pendingToken = nil
    }

}
