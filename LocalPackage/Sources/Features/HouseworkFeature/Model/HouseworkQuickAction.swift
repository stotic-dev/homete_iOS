//
//  HouseworkQuickAction.swift
//  homete
//

import HometeDomain
import SwiftUI

/// 家事リストのセルからワンタップで行えるアクション
enum HouseworkQuickAction: Identifiable, Equatable, CaseIterable {

    /// 完了にする（未完了 → 完了）
    case complete
    /// やらない（未完了 → やらない）
    case remove
    /// ありがとう（完了した家事に感謝を伝える。ステータスは変わらない）
    case sendThanks
    /// もう一度やった（完了した家事と同じ家事を、完了済みとして新しく登録する。元の家事は変わらない）
    case redo
    /// 未完了に戻す（完了 → 未完了）
    case returnToIncomplete

    var id: Self {
        self
    }

    var label: String {
        switch self {
        case .complete:
            "完了にする"
        case .remove:
            "やらない"
        case .sendThanks:
            "ありがとう"
        case .redo:
            "もう一度やった"
        case .returnToIncomplete:
            "未完了に戻す"
        }
    }

    var systemImage: String {
        switch self {
        case .complete:
            "checkmark.circle.fill"
        case .remove:
            "trash"
        case .sendThanks:
            "hands.clap.fill"
        case .redo:
            "arrow.clockwise"
        case .returnToIncomplete:
            "arrow.uturn.backward"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .remove:
            .destructive
        case .complete, .sendThanks, .redo, .returnToIncomplete:
            nil
        }
    }

}

extension HouseworkQuickAction {

    /// ワンタップ実行時に自動設定する定型コメント（`sendThanks`のみ使用）
    var fixedComment: String {
        switch self {
        case .sendThanks:
            "ありがとう！"
        case .complete, .remove, .redo, .returnToIncomplete:
            ""
        }
    }

    /// 一括操作で相手に送る、まとめ通知の内容
    ///
    /// 家事ごとに個別通知を送ると件数分の通知が届いてしまうため、一括操作では対象件数をまとめた
    /// 1件の通知のみを送る。相手に表示する通知を送らないアクション（完了・やらない・未完了に戻す）は`nil`。
    /// - Note: 完了はふりかえり通知の予約を兼ねた完了通知を、1日1回だけ送る（`performBulk`）
    func bulkNotification(count: Int, senderName: String) -> PushNotificationContent? {
        switch self {
        case .sendThanks:
            .thanksBulkMessage(senderName: senderName, count: count)
        case .complete, .remove, .redo, .returnToIncomplete:
            nil
        }
    }

}

extension HouseworkQuickAction {

    /// 複数選択の一括操作で行えるかどうか
    ///
    /// もう一度やったは、選択した件数分の家事がまとめて増えてしまうため一括操作の対象にしない
    var isAvailableInBulk: Bool {
        switch self {
        case .redo:
            false
        case .complete, .remove, .sendThanks, .returnToIncomplete:
            true
        }
    }

}

extension HouseworkQuickAction {

    /// 家事の状態・実施者に応じて、その家事に対して行えるクイックアクションを返す
    static func actions(for item: HouseworkBoardItem, ownUserId: String) -> [Self] {
        switch item.state {
        case .incomplete:
            [.complete, .remove]

        // 自分が終えた家事に自分でありがとうを送れてしまわないようにする
        case .completed:
            item.canSendThanks(ownUserId: ownUserId)
                ? [.sendThanks, .redo, .returnToIncomplete]
                : [.redo, .returnToIncomplete]

        case .notTodo:
            []
        }
    }

    /// 状態のみに応じたクイックアクションを返す
    ///
    /// 一括操作バーで、まだ何も選択されていないときに表示する既定のボタンを決めるために使う。
    static func actions(for state: HouseworkState) -> [Self] {
        switch state {
        case .incomplete:
            [.complete, .remove]

        case .completed:
            [.sendThanks, .returnToIncomplete]

        case .notTodo:
            []
        }
    }

}
