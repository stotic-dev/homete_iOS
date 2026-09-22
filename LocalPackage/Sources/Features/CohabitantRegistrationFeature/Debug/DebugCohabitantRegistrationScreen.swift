//
//  DebugCohabitantRegistrationScreen.swift
//  LocalPackage
//

#if DEBUG

import HometeDomain
import HometeUI
import SwiftUI

/// 登録済みのアカウントでもP2P登録フローを通しで確認するためのデバッグ画面
///
/// 複数台でこの画面を開くと、実際のP2P通信で役割決め・同居人IDの共有・完了の待ち合わせまでを行う。
/// Firestoreへの書き込み（同居人レコードの作成・自分のアカウントへの同居人IDの保存）だけをモックに差し替えるため、
/// すでに同居人グループに所属している端末でも、実データを壊さずに完走できるかを確認できる。
public struct DebugCohabitantRegistrationScreen: View {

    @Environment(\.loginContext.account) var account

    /// モックが受け取った書き込みの記録
    @State var log = DebugCohabitantRegistrationLog()

    public init() {}

    public var body: some View {
        CohabitantRegistrationView()
            // Firestoreへの書き込み・Analyticsの送信を実環境に飛ばさないため、
            // 依存をまるごとpreviewValueにした上で、記録用のモックだけ差し込む
            .environment(\.appDependencies, .init(cohabitantClient: log.mockCohabitantClient))
            .environment(AccountStore(accountInfoClient: log.mockAccountInfoClient(account), account: account))
            // 重ねて表示すると画面下部の「登録を開始する」ボタンを覆ってタップできなくなるため、
            // 登録画面の下に領域を確保して並べる
            .safeAreaInset(edge: .bottom) {
                DebugCohabitantRegistrationLogView(log: log)
            }
    }

}

/// モックが受け取った書き込みを画面に出すための記録
@MainActor
@Observable
final class DebugCohabitantRegistrationLog {

    /// 作成された同居人グループ（リーダー側だけ記録される）
    private(set) var registeredCohabitant: CohabitantData?
    /// 自分のアカウントへ保存された同居人ID
    private(set) var savedCohabitantId: String?

    /// 同居人レコードの作成を記録だけして成功させるClient
    var mockCohabitantClient: CohabitantClient {
        .init(register: { [weak self] cohabitant in
            await MainActor.run { self?.registeredCohabitant = cohabitant }
        })
    }

    /// アカウントの更新を記録だけして成功させるClient
    /// - Parameter account: 画面入口のアカウント確認（`reload`）で返す自分のアカウント
    func mockAccountInfoClient(_ account: Account) -> AccountInfoClient {
        .init(
            insertOrUpdate: { [weak self] updatedAccount in
                await MainActor.run { self?.savedCohabitantId = updatedAccount.cohabitantId }
            },
            fetch: { _ in account }
        )
    }

}

/// モックが受け取った内容を確認するための表示
private struct DebugCohabitantRegistrationLogView: View {

    let log: DebugCohabitantRegistrationLog

    var body: some View {
        VStack(alignment: .leading, spacing: .space4) {
            Text("デバッグ実行中です。グループの作成・保存はモックのため、実際のデータは変わりません。")
            Text("作成したグループ: \(log.registeredCohabitant.map { "\($0.id)（\($0.members.count)人）" } ?? "なし")")
            Text("保存した同居人ID: \(log.savedCohabitantId ?? "なし")")
        }
        .font(with: .caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.space8)
        .background(.subSurface)
        .padding(.horizontal, .space16)
        .padding(.bottom, .space8)
    }

}

#endif
