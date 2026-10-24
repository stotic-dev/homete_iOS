//
//  PastThanksTargetListScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 過去のありがとう漏れの一覧の画面
///
/// ダッシュボードの過去の促しと、今日のありがとう一覧の末尾のリンクから開く。
/// ハートのタップでありがとうだけを、行のタップでメッセージを添えて伝えられる。
/// 開いてから送った家事は一覧から消さず、送信済みの表示に切り替える（送った直後に行が消えて戸惑わないように）。
public struct PastThanksTargetListScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var members
    @Environment(HouseworkListStore.self) var houseworkListStore

    @CommonError var commonError
    /// 一覧を開いた日時。これ以降に送った家事は、送信済みとして一覧に残す
    @State var openedAt: Date?
    /// メッセージを添えるハーフモーダルを出している家事
    @State var thankingItem: HouseworkBoardItem?
    /// 初めてありがとうを伝えたときの演出の回数
    @State var thanksFeedbackCount = 0
    /// ハーフモーダルで初めてありがとうを伝え、モーダルが閉じきるのを待って演出を出す
    @State var hasPendingThanksFeedback = false

    public static func make() -> some View {
        PastThanksTargetListScreen()
    }

    public var body: some View {
        PastThanksTargetListView(
            summary: PastThanksPromptSummary.make(
                storedAllItems: houseworkListStore.items,
                members: members,
                ownUserId: loginContext.account.id,
                now: now,
                calendar: calendar,
                keepingSentSince: openedAt ?? now
            ),
            ownUserId: loginContext.account.id,
            members: members,
            onTapRow: { thankingItem = $0 },
            onTapThanks: { item in Task { await sendThanks(to: item) } }
        )
        .onAppear {
            guard openedAt == nil else { return }

            openedAt = now
        }
        .sheet(item: $thankingItem, onDismiss: dismissedThanksView) { item in
            HouseworkThanksView(
                item: item,
                sentThanks: item.sentThanks(ownUserId: loginContext.account.id),
                step: .commentPrompt
            ) {
                hasPendingThanksFeedback = true
            }
        }
        .thanksFeedback(trigger: thanksFeedbackCount)
        .commonError(content: $commonError)
        .trackScreenView(.pastThanksTargetList)
    }

}

// MARK: プレゼンテーションロジック

private extension PastThanksTargetListScreen {

    /// ハートのタップでは、メッセージを書かずにありがとうだけを伝える（コメントがないので通知は送らない）
    func sendThanks(to item: HouseworkBoardItem) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            let isFirstThanks = try await houseworkListStore.perform(
                .sendThanks,
                on: item,
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: .commentPrompt
            )
            if isFirstThanks {
                thanksFeedbackCount += 1
            }
        } catch {
            commonError = .init(error: error)
        }
    }

    func dismissedThanksView() {
        guard hasPendingThanksFeedback else { return }

        hasPendingThanksFeedback = false
        thanksFeedbackCount += 1
    }

}
