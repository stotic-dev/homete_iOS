//
//  AppReviewRequestModifier.swift
//

import HometeDomain
import StoreKit
import SwiftUI

/// アプリの価値を感じたと考えられるタイミングで、OS標準の評価ダイアログをリクエストする
///
/// プランの変化と家事一覧の変化を見て`AppReviewPolicy`に判定させる。
/// - Note: オンボーディング中の課金は対象にしないため、ログイン後の`AppTabView`に付ける
private struct AppReviewRequestModifier: ViewModifier {

    @Environment(\.requestReview) var requestReview
    @Environment(\.appDependencies.appReviewStateClient) var appReviewStateClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.loginContext) var loginContext
    @Environment(SubscriptionStore.self) var subscriptionStore

    /// 待ってから評価ダイアログをリクエストする処理。画面が消えたら取り消す
    @State var requestTask: Task<Void, Never>?

    let houseworkItems: StoredAllHouseworkList?

    func body(content: Content) -> some View {
        content
            .onAppear {
                onAppear()
            }
            .onDisappear {
                // ログアウトなどで画面が消えた後に、別の画面の上でダイアログを出さない
                requestTask?.cancel()
            }
            .onChange(of: subscriptionStore.entitlementInfo) { oldValue, newValue in
                onChangeEntitlementInfo(from: oldValue, to: newValue)
            }
            .onChange(of: houseworkItems) {
                onChangeHouseworkItems()
            }
    }

}

// MARK: プレゼンテーションロジック

private extension AppReviewRequestModifier {

    func onAppear() {
        _ = loadPolicy()
        // 表示する前に届いていた家事一覧は`onChange`では拾えないため、表示した時点の一覧でも判定する
        onChangeHouseworkItems()
    }

    /// 保存済みの記録から判定を組み立てる。初めてなら使い始めた日時を記録する
    /// - Note: 記録はデバッグメニューからも書き換えるため、画面に持たず判定のたびに読み直す
    func loadPolicy() -> AppReviewPolicy {
        let savedState = appReviewStateClient.load()
        let policy = AppReviewPolicy(savedState: savedState, now: .now)
        if savedState == nil {
            appReviewStateClient.save(policy.state)
        }
        return policy
    }

    func onChangeEntitlementInfo(from oldValue: EntitlementInfo?, to newValue: EntitlementInfo?) {
        let policy = loadPolicy()
        guard let trigger = policy.purchaseTrigger(from: oldValue, to: newValue, now: .now) else { return }

        request(trigger, policy: policy)
    }

    func onChangeHouseworkItems() {
        guard let houseworkItems else { return }

        let policy = loadPolicy()
        var updatedPolicy = policy
        let trigger = updatedPolicy.receiveThanks(
            in: houseworkItems,
            accountId: loginContext.account.id,
            now: .now
        )
        guard updatedPolicy != policy else { return }

        if let trigger {
            request(trigger, policy: updatedPolicy)
        } else {
            appReviewStateClient.save(updatedPolicy.state)
        }
    }

    /// 少し待ってから評価ダイアログをリクエストする
    /// - Note: 待っている間に別のきっかけで重ねてリクエストしないよう、待つ前に記録する。
    ///         課金ではペイウォールが閉じるアニメーションと重ならないよう、ありがとうでは画面の表示が落ち着くまで待つ
    func request(_ trigger: AppReviewTrigger, policy: AppReviewPolicy) {
        var updatedPolicy = policy
        updatedPolicy.markRequested(trigger, now: .now)
        appReviewStateClient.save(updatedPolicy.state)
        // 待っている処理が残っていれば、ダイアログを続けて出さないよう取り消してから置き換える
        requestTask?.cancel()
        requestTask = Task {
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            requestReview()
            analyticsClient.log(.appReview(trigger: trigger))
        }
    }

}

extension View {

    /// アプリの価値を感じたと考えられるタイミングで、評価ダイアログをリクエストする
    /// - Parameter houseworkItems: ありがとうを数える家事一覧。グループ未所属などで無い場合は`nil`
    func appReviewRequest(houseworkItems: StoredAllHouseworkList?) -> some View {
        modifier(AppReviewRequestModifier(houseworkItems: houseworkItems))
    }

}
