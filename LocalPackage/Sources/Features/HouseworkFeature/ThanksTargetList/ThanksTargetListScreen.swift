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
/// 選択モードでは、選んだ家事へ一括でありがとうを送れる。
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
    /// 複数選択モードかどうか
    @State var isSelecting = false
    /// 複数選択モードで選択中の家事のID
    @State var selectedIDs: Set<String> = []

    /// 過去のありがとう漏れの一覧へのリンクをタップした
    let onTapPastList: () -> Void

    public static func make(onTapPastList: @escaping () -> Void) -> some View {
        ThanksTargetListScreen(onTapPastList: onTapPastList)
    }

    public var body: some View {
        ThanksTargetListView(
            summary: summary,
            ownUserId: loginContext.account.id,
            members: members,
            isSelecting: $isSelecting,
            selectedIDs: $selectedIDs,
            onTapRow: { thankingItem = $0 },
            onTapThanks: { item in Task { await sendThanks(to: item) } },
            onTapPastList: onTapPastList,
            onTapBulkThanks: sendThanksBulk
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

    var summary: ThanksPromptSummary {
        ThanksPromptSummary.make(
            storedAllItems: houseworkListStore.items,
            members: members,
            ownUserId: loginContext.account.id,
            now: now,
            calendar: calendar
        )
    }

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

    /// 選択した家事へ、まとめてありがとうだけを伝える（コメントがないので通知は送らない）
    ///
    /// 家事ボードの一括操作と同じく、対象を確定したらすぐに選択モードを抜け、書き込みの完了は待たない。
    /// まとめて書き込むので失敗したときは全件が反映されておらず、エラーを見たユーザーは選び直せばよい。
    func sendThanksBulk() {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        let targets = ThanksTargetSelection(
            items: summary.thankableItems,
            selectedIDs: selectedIDs,
            ownUserId: loginContext.account.id
        ).targets
        withAnimation {
            isSelecting = false
        }
        Task {
            do {
                let hasSentFirstThanks = try await houseworkListStore.performBulk(
                    .sendThanks,
                    on: targets,
                    now: now,
                    account: loginContext.account,
                    cohabitantId: cohabitantId,
                    step: .commentPrompt
                )
                // 何件伝えても演出は1回だけにする
                if hasSentFirstThanks {
                    thanksFeedbackCount += 1
                }
            } catch {
                commonError = .init(error: error)
            }
        }
    }

    func dismissedThanksView() {
        guard hasPendingThanksFeedback else { return }

        hasPendingThanksFeedback = false
        thanksFeedbackCount += 1
    }

}
