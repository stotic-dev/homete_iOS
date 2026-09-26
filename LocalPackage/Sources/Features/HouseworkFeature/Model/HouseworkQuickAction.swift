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
        case .returnToIncomplete:
            "arrow.uturn.backward"
        }
    }

    var role: ButtonRole? {
        switch self {
        case .remove:
            .destructive
        case .complete, .sendThanks, .returnToIncomplete:
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
        case .complete, .remove, .returnToIncomplete:
            ""
        }
    }

    /// 一括操作で相手に送る、まとめ通知の内容
    ///
    /// 家事ごとに個別通知を送ると件数分の通知が届いてしまうため、一括操作では対象件数をまとめた
    /// 1件の通知のみを送る。相手に表示する通知を送らないアクション（完了・やらない・未完了に戻す）は`nil`。
    /// - Note: 完了は表示する通知の代わりに、ふりかえり通知の予約に使うサイレント通知を送る（`performBulk`）
    func bulkNotification(count: Int, senderName: String) -> PushNotificationContent? {
        switch self {
        case .sendThanks:
            .thanksBulkMessage(senderName: senderName, count: count)
        case .complete, .remove, .returnToIncomplete:
            nil
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
            item.canSendThanks(ownUserId: ownUserId) ? [.sendThanks, .returnToIncomplete] : [.returnToIncomplete]

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
