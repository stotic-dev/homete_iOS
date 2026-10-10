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

    /// 記録を読み込むまでは`nil`。読み込む前の変化は判定しない
    @State var policy: AppReviewPolicy?

    let houseworkItems: StoredAllHouseworkList?

    func body(content: Content) -> some View {
        content
            .task {
                await loadPolicy()
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

    func loadPolicy() async {
        let savedState = await appReviewStateClient.load()
        let loadedPolicy = AppReviewPolicy(savedState: savedState, now: .now)
        policy = loadedPolicy
        if savedState == nil {
            await appReviewStateClient.save(loadedPolicy.state)
        }
        // 読み込んでいる間に届いた家事一覧を取りこぼさないよう、読み込んだ時点の一覧でも判定する
        onChangeHouseworkItems()
    }

    func onChangeEntitlementInfo(from oldValue: EntitlementInfo?, to newValue: EntitlementInfo?) {
        guard let trigger = policy?.purchaseTrigger(from: oldValue, to: newValue, now: .now) else { return }

        request(trigger)
    }

    func onChangeHouseworkItems() {
        guard var updatedPolicy = policy, let houseworkItems else { return }

        let trigger = updatedPolicy.receiveThanks(
            in: houseworkItems,
            accountId: loginContext.account.id,
            now: .now
        )
        guard updatedPolicy != policy else { return }

        policy = updatedPolicy
        if let trigger {
            request(trigger)
        } else {
            save(updatedPolicy.state)
        }
    }

    /// 少し待ってから評価ダイアログをリクエストする
    /// - Note: 待っている間に別のきっかけで重ねてリクエストしないよう、待つ前に記録する。
    ///         課金ではペイウォールが閉じるアニメーションと重ならないよう、ありがとうでは画面の表示が落ち着くまで待つ
    func request(_ trigger: AppReviewTrigger) {
        guard var updatedPolicy = policy else { return }

        updatedPolicy.markRequested(trigger, now: .now)
        policy = updatedPolicy
        save(updatedPolicy.state)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            requestReview()
            analyticsClient.log(.appReview(trigger: trigger))
        }
    }

    func save(_ state: AppReviewState) {
        Task {
            await appReviewStateClient.save(state)
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
