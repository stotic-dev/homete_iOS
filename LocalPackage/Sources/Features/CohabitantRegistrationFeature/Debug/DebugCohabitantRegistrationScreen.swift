//
//  DebugCohabitantRegistrationScreen.swift
//  LocalPackage
//

#if DEBUG

import HometeDomain
import SwiftUI

/// 登録済みのアカウントでもP2P登録フローを通しで確認するためのデバッグ画面
///
/// 複数台でこの画面を開くと、実際のP2P通信で役割決め・同居人IDの共有・完了の待ち合わせまでを行う。
/// Firestoreへの書き込み（同居人レコードの作成・自分のアカウントへの同居人IDの保存）だけをモックに差し替えるため、
/// すでに同居人グループに所属している端末でも、実データを壊さずに完走できるかを確認できる。
public struct DebugCohabitantRegistrationScreen: View {

    @Environment(\.loginContext.account) var account

    public init() {}

    public var body: some View {
        CohabitantRegistrationView()
            // Firestoreへの書き込み・Analyticsの送信を実環境に飛ばさないため、
            // 依存をまるごとpreviewValueにした上で、書き込みを握り潰すモックだけ差し込む
            .environment(\.appDependencies, .init(cohabitantClient: .debugMock))
            .environment(AccountStore(accountInfoClient: .debugMock(account: account), account: account))
    }

}

private extension CohabitantClient {

    /// 同居人レコードを作らずに成功させるClient
    static var debugMock: Self {
        .init(register: { _ in })
    }

}

private extension AccountInfoClient {

    /// アカウントを更新せずに成功させるClient
    /// - Parameter account: 画面入口のアカウント確認（`reload`）で返す自分のアカウント
    static func debugMock(account: Account) -> Self {
        .init(
            insertOrUpdate: { _ in },
            fetch: { _ in account }
        )
    }

}

#endif
