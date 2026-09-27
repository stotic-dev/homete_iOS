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
    ///
    /// 1件ではメッセージを入力するハーフモーダルを出す。一括操作ではコメントなしで記録し、通知も送らない。
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

        // 自分が終えた家事や、すでにありがとうを送った家事には出さない
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
