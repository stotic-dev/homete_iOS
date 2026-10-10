//
//  HouseworkQuickAction.swift
//  homete
//

import HometeDomain

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
    /// 手伝った人を追加（完了した家事に担当者を足して、ポイントを配り直す）
    ///
    /// 担当者と配分を決めるハーフモーダルを出す。家事の合計ポイントは変わらない。
    case addHelper
    /// もう一度やった（完了した家事と同じ家事を、完了済みとして新しく登録する。元の家事は変わらない）
    case redo
    /// 未完了に戻す（完了 → 未完了）
    case returnToIncomplete

    var id: Self {
        self
    }

}

extension HouseworkQuickAction {

    /// 複数選択の一括操作で行えるかどうか
    ///
    /// もう一度やったは、選択した件数分の家事がまとめて増えてしまうため一括操作の対象にしない。
    /// 手伝った人の追加は、家事ごとに担当者と配分を決める操作なので同じく対象にしない。
    var isAvailableInBulk: Bool {
        switch self {
        case .redo, .addHelper:
            false
        case .complete, .remove, .sendThanks, .returnToIncomplete:
            true
        }
    }

}

extension HouseworkQuickAction {

    /// 家事の状態・実施者に応じて、その家事に対して行えるクイックアクションを返す
    ///
    /// 並び順はメニューに出す順番。
    /// - Parameter canAddHelper: 手伝った人を足せるかどうか（足せる相手がいないときは出さない）
    static func actions(for item: HouseworkBoardItem, ownUserId: String, canAddHelper: Bool) -> [Self] {
        switch item.state {
        case .incomplete:
            return [.complete, .remove]

        case .completed:
            var actions: [Self] = []
            // ありがとうは、自分が終えた家事や、すでにありがとうを送った家事には出さない
            if item.canSendThanks(ownUserId: ownUserId) {
                actions.append(.sendThanks)
            }
            // 感謝と並ぶpositiveな操作なので、取り消し系（もう一度やった・未完了に戻す）より前に置く
            if canAddHelper {
                actions.append(.addHelper)
            }
            return actions + [.redo, .returnToIncomplete]

        case .notTodo:
            return []
        }
    }

    /// 状態のみに応じたクイックアクションを返す
    ///
    /// 未完了の家事だけを並べる一覧のように、状態だけで出せるアクションが決まる画面で使う。
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
