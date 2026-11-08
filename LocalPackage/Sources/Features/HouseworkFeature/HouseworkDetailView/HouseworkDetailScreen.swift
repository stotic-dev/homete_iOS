//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import HometeAppCore
import HouseworkFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkDetailScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.routeResolver) var router
    @LoadingState var loadingState

    @State var item: HouseworkBoardItem
    @State var isPresentedCompleteSheet = false
    @State var isPresentedThanksView = false
    @State var isPresentedAddHelperSheet = false
    @State var isPresentedMemoEditSheet = false
    @State var isPresentedMemoNotEditableAlert = false
    @State var isPresentedPostponeDatePicker = false
    /// カレンダーで選んだ、まわす先の日。カレンダーが閉じきるのを待ってからまわす
    @State var pendingPostponeDate: Date?
    /// 別の日へまわす前に、確認のアラートで確かめている内容
    @State var postponeConfirmation: HouseworkPostponeConfirmation?
    /// チェックの保存中か
    /// - Note: 保存がリスナーに反映される前に次のチェックを保存すると、古いメモを元に書いて先のチェックを消すため、1つずつ保存する
    @State var isSavingMemoCheck = false
    /// 初めてありがとうを伝えた回数。増えるたびにありがとうの演出を出す
    @State var thanksFeedbackCount = 0
    /// ハーフモーダルで初めてありがとうを伝え、モーダルが閉じきるのを待って演出を出す
    @State var hasPendingThanksFeedback = false

    @CommonError var commonErrorContent

    public static func make(item: HouseworkBoardItem) -> some View {
        HouseworkDetailScreen(item: item)
    }

    public var body: some View {
        HouseworkDetailView(
            item: item,
            cohabitantMemberList: cohabitantStore.members,
            primaryAction: primaryAction,
            menuActions: menuActions,
            isSavingMemoCheck: isSavingMemoCheck,
            isLoading: loadingState.isLoading,
            onTapAction: tappedAction,
            onTapEditMemo: { isPresentedMemoEditSheet = true },
            onToggleMemoChecklistItem: { checklistItemId in tappedMemoChecklistItem(checklistItemId) },
            imageSection: {
                HouseworkDetailImageComponent(
                    item: item,
                    loadingState: loadingState,
                    onError: { commonErrorContent = .init(error: $0) }
                )
            }
        )
        .fullScreenLoadingIndicator(loadingState)
        .sheet(isPresented: $isPresentedCompleteSheet) {
            HouseworkCompleteSheet(item: item, step: .detail)
        }
        // モーダルの上ではなく、閉じた後の詳細画面に演出を出す。モーダルを閉じるのを演出で待たせないため
        .sheet(isPresented: $isPresentedThanksView, onDismiss: dismissedThanksView) {
            HouseworkThanksScreen(item: item, sentThanks: item.sentThanks(ownUserId: account.id)) {
                hasPendingThanksFeedback = true
            }
        }
        .sheet(isPresented: $isPresentedAddHelperSheet) {
            HouseworkAddHelperSheet(item: item, step: .detail)
        }
        // 確認のアラートを出すことがあるため、カレンダーが閉じきってからまわす。閉じている途中に出すと表示されないことがある
        .sheet(isPresented: $isPresentedPostponeDatePicker, onDismiss: dismissedPostponeDatePicker) {
            postponeDatePicker()
        }
        .houseworkPostponeConfirmation(
            $postponeConfirmation,
            step: .detail,
            // まわした家事はこの日の一覧から消えるため、詳細を閉じて家事ボードへ戻る
            onPostponed: { dismiss() },
            onError: { commonErrorContent = .init(error: $0) }
        )
        .commonError(content: $commonErrorContent)
        .sheet(isPresented: $isPresentedMemoEditSheet) {
            HouseworkMemoEditScreen(memo: item.originalItem.memo, isPremium: subscriptionStore.isPremium) { memo in
                savedMemo(memo)
            } paywall: {
                router.resolve(.paywall(step: .houseworkMemoLimit))
            }
            .trackScreenView(.houseworkMemoEdit)
        }
        .alert(.localized("メモを保存できませんでした"), isPresented: $isPresentedMemoNotEditableAlert) {
            Button(.localized("閉じる"), role: .cancel) {}
        } message: {
            Text("この家事は完了または「やらない」になったため、メモを編集できません。", bundle: #bundle)
        }
        .onChange(of: houseworkListStore.items) {
            didChangeItems()
        }
        .thanksFeedback(trigger: thanksFeedbackCount)
        .trackScreenView(.houseworkDetail)
    }

}

// MARK: 表示内容

private extension HouseworkDetailScreen {

    var memoLimitPolicy: HouseworkMemoLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailScreen {

    /// この家事に対して行えるアクション（ナビゲーションバーとメニューに出す順番）
    var actions: [HouseworkDetailAction] {
        HouseworkDetailAction.actions(for: item, ownUserId: account.id, canAddHelper: canAddHelper)
    }

    /// ナビゲーションバーに単独のボタンとして出すアクション
    var primaryAction: HouseworkDetailAction? {
        actions.first(where: \.isPrimary)
    }

    /// 「その他」のメニューに入れるアクション
    var menuActions: [HouseworkDetailAction] {
        actions.filter { !$0.isPrimary }
    }

    /// 手伝った人を足せるかどうか
    var canAddHelper: Bool {
        item.canAddHelper(members: cohabitantStore.members)
    }

    func tappedAction(_ action: HouseworkDetailAction) {
        switch action {
        case .complete:
            isPresentedCompleteSheet = true

        case .sendThanks, .addThanksMessage, .editThanksMessage:
            isPresentedThanksView = true

        case .addHelper:
            isPresentedAddHelperSheet = true

        case .postpone:
            isPresentedPostponeDatePicker = true

        case .redo, .returnToIncomplete, .remove:
            loadingState.task {
                await perform(action)
            }
        }
    }

    /// ハーフモーダルを挟まないアクションを実行する
    func perform(_ action: HouseworkDetailAction) async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            switch action {
            case .redo:
                try await houseworkListStore.redo(
                    target: item.originalItem,
                    now: now,
                    executor: account,
                    cohabitantId: cohabitantId,
                    step: .detail
                )

            case .returnToIncomplete:
                try await houseworkListStore.returnToIncomplete(
                    target: item.originalItem,
                    cohabitantId: cohabitantId,
                    step: .detail
                )

            case .remove:
                try await houseworkListStore.remove(
                    target: item.originalItem,
                    cohabitantId: cohabitantId,
                    isRegistered: item.isRegistered,
                    step: .detail
                )
                // 一覧から取り下げた家事の詳細は見られても意味がないため閉じる
                dismiss()

            case .complete, .sendThanks, .addThanksMessage, .editThanksMessage, .addHelper, .postpone:
                // ハーフモーダルで入力を受け取ってから実行するアクション
                break
            }
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

    func dismissedThanksView() {
        guard hasPendingThanksFeedback else { return }
        hasPendingThanksFeedback = false
        thanksFeedbackCount += 1
    }

    func savedMemo(_ memo: HouseworkMemo) {
        guard let cohabitantId = account.cohabitantId else { return }

        let target = item
        loadingState.task {
            do {
                try await houseworkListStore.updateMemo(
                    target: target.originalItem,
                    memo: memo,
                    cohabitantId: cohabitantId,
                    isRegistered: target.isRegistered,
                    step: .detail,
                    limitPolicy: memoLimitPolicy
                )
            } catch {
                handleMemoError(error)
            }
        }
    }

    func tappedMemoChecklistItem(_ checklistItemId: HouseworkMemoChecklistItem.ID) {
        let target = item
        guard let cohabitantId = account.cohabitantId,
              let memo = target.originalItem.memo,
              !isSavingMemoCheck,
              let toggledItem = try? target.originalItem.updateMemo(
                  memo.toggled(checklistItemId),
                  limitPolicy: memoLimitPolicy
              ) else { return }

        // 保存を待たずにチェックを反映し、失敗したら元に戻す
        item = .init(originalItem: toggledItem, isRegistered: target.isRegistered)
        isSavingMemoCheck = true
        Task {
            defer { isSavingMemoCheck = false }
            do {
                try await houseworkListStore.toggleMemoChecklistItem(
                    target: target.originalItem,
                    itemId: checklistItemId,
                    cohabitantId: cohabitantId,
                    isRegistered: target.isRegistered,
                    limitPolicy: memoLimitPolicy
                )
            } catch {
                item = houseworkListStore.items.item(target.originalItem)
                    .map { .init(originalItem: $0, isRegistered: true) } ?? target
                handleMemoError(error)
            }
        }
    }

    func handleMemoError(_ error: any Error) {
        if error as? HouseworkMemoError == .notEditable {
            isPresentedMemoNotEditableAlert = true
        } else {
            commonErrorContent = .init(error: error)
        }
    }

    func didChangeItems() {
        // テンプレートの家事を別の日へまわすと、元の日に同じIDの記録が残る。画面を閉じる前にその記録
        // （「やらない」）へ切り替わって見えないよう、反映しない
        guard let targetItem = houseworkListStore.items.item(item.originalItem),
              !targetItem.isPostponedRecord else { return }

        withAnimation {
            item = .init(originalItem: targetItem, isRegistered: true)
        }
    }

}
