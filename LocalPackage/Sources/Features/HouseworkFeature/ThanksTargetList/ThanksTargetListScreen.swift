//
//  ThanksTargetListScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ありがとうを伝えられる家事の一覧の画面
///
/// ダッシュボードの感謝の促しから開く。今日に同居人が終えた家事を並べ、
/// ハートのタップでありがとうだけを、行のタップでメッセージを添えて伝えられる。
/// 送った家事も一覧から消さず、送信済みの表示に切り替える（送った直後に行が消えて戸惑わないように）。
public struct ThanksTargetListScreen: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var members
    @Environment(HouseworkListStore.self) var houseworkListStore

    @CommonError var commonError
    /// メッセージを添えるハーフモーダルを出している家事
    @State var thankingItem: HouseworkBoardItem?
    /// 初めてありがとうを伝えたときの演出の回数
    @State var thanksFeedbackCount = 0
    /// ハーフモーダルで初めてありがとうを伝え、モーダルが閉じきるのを待って演出を出す
    @State var hasPendingThanksFeedback = false

    /// 過去のありがとう漏れの一覧へのリンクをタップした
    let onTapPastList: () -> Void

    public static func make(onTapPastList: @escaping () -> Void) -> some View {
        ThanksTargetListScreen(onTapPastList: onTapPastList)
    }

    public var body: some View {
        ThanksTargetListView(
            summary: ThanksPromptSummary.make(
                storedAllItems: houseworkListStore.items,
                members: members,
                ownUserId: loginContext.account.id,
                now: now,
                calendar: calendar
            ),
            ownUserId: loginContext.account.id,
            members: members,
            onTapRow: { thankingItem = $0 },
            onTapThanks: { item in Task { await sendThanks(to: item) } },
            onTapPastList: onTapPastList
        )
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
        .trackScreenView(.thanksTargetList)
    }

}

// MARK: プレゼンテーションロジック

private extension ThanksTargetListScreen {

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
