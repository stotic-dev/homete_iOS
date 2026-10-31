//
//  HouseworkQuickAction.swift
//  homete
//

import Foundation
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
    /// 明日にまわす（今日の未完了の家事を翌日へ移す）
    case postponeToTomorrow
    /// 今日にまわす（昨日の未完了の家事を翌日、つまり今日へ移す）
    case postponeToToday

    var id: Self {
        self
    }

}

extension HouseworkQuickAction {

    /// 複数選択の一括操作で行えるかどうか
    ///
    /// もう一度やったは、選択した件数分の家事がまとめて増えてしまうため一括操作の対象にしない。
    /// 手伝った人の追加は、家事ごとに担当者と配分を決める操作なので同じく対象にしない。
    /// まわす操作は、まとめるかどうか・同じ名前の家事があるかを家事ごとに確かめるため対象にしない。
    var isAvailableInBulk: Bool {
        switch self {
        case .redo, .addHelper, .postponeToTomorrow, .postponeToToday:
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

    /// 1件の家事のメニュー（長押し・その他ボタン）に出すクイックアクションを返す
    ///
    /// `actions(for:ownUserId:canAddHelper:)`に、家事の日付で出し分ける「まわす」を「やらない」の前に足す。
    /// 「まわす」は複数選択の判定に含めないため、`actions(for:ownUserId:canAddHelper:)`には入れない。
    /// - Parameter canAddHelper: 手伝った人を足せるかどうか（足せる相手がいないときは出さない）
    static func menuActions(
        for item: HouseworkBoardItem,
        ownUserId: String,
        canAddHelper: Bool,
        now: Date,
        calendar: Calendar
    ) -> [Self] {
        var result = Self.actions(for: item, ownUserId: ownUserId, canAddHelper: canAddHelper)
        guard let postpone = Self.postponeAction(for: item, now: now, calendar: calendar),
              let removeIndex = result.firstIndex(of: .remove) else { return result }

        result.insert(postpone, at: removeIndex)
        return result
    }

    /// 家事の日付に応じた「まわす」のアクション
    ///
    /// 今日の家事は明日へ、昨日の家事は今日へまわせる。それより前や先の日の家事は、家事詳細から日付を選んでまわす。
    static func postponeAction(for item: HouseworkBoardItem, now: Date, calendar: Calendar) -> Self? {
        guard item.state == .incomplete else { return nil }

        let today = calendar.startOfDay(for: now)
        let itemDay = calendar.startOfDay(for: item.originalItem.indexedDate.value)
        if itemDay == today {
            return .postponeToTomorrow
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), itemDay == yesterday {
            return .postponeToToday
        }
        return nil
    }

    /// 「明日にまわす」「今日にまわす」でまわす先の日（家事の日付の翌日）
    static func nextDay(of item: HouseworkBoardItem, calendar: Calendar) -> Date? {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: item.originalItem.indexedDate.value))
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
