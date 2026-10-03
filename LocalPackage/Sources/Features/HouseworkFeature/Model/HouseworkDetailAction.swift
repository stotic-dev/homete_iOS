//
//  HouseworkDetailAction.swift
//  LocalPackage
//

import HometeDomain

/// 家事詳細で行えるアクション
///
/// クイックアクション（`HouseworkQuickAction`）とは別に定義する。詳細では「手伝った人を追加」と
/// 「ありがとうのメッセージ編集」も行える一方、これらは1件ずつ配分やメッセージを決める操作なので
/// 家事ボードのクイックアクション・一括操作には出さない。
enum HouseworkDetailAction: Identifiable, Equatable, CaseIterable {

    /// 完了にする（未完了 → 完了）
    case complete
    /// ありがとうを伝える
    case sendThanks
    /// コメントなしで送ったありがとうに、後からメッセージを書き足す
    case addThanksMessage
    /// 送ったありがとうのメッセージを直す
    case editThanksMessage
    /// 完了した家事に手伝った人を追加する
    case addHelper
    /// もう一度やった（同じ家事を完了済みとして新しく登録する）
    case redo
    /// 未完了に戻す（完了 → 未完了）
    case returnToIncomplete
    /// やらない（家事を一覧から取り下げる）
    case remove

    var id: Self {
        self
    }

}

extension HouseworkDetailAction {

    /// ナビゲーションバーに単独のボタンとして出すかどうか
    ///
    /// その状態で一番よく使う操作だけを出して、残りは「その他」のメニューに入れる。
    /// ステータスを変える操作や取り下げる操作は、誤ってタップしても取り返しがつくように単独では出さない。
    var isPrimary: Bool {
        switch self {
        case .complete, .sendThanks, .addThanksMessage, .editThanksMessage:
            true

        case .addHelper, .redo, .returnToIncomplete, .remove:
            false
        }
    }

}

extension HouseworkDetailAction {

    /// 家事の状態・ありがとうの送信状況に応じて、その家事に対して行えるアクションを返す
    ///
    /// 並び順はナビゲーションバーとメニューに出す順番。
    /// - Parameter canAddHelper: 手伝った人を足せるかどうか（足せる相手がいないときは出さない）
    static func actions(
        for item: HouseworkBoardItem,
        ownUserId: String,
        canAddHelper: Bool
    ) -> [Self] {
        switch item.state {
        case .incomplete:
            return [.complete, .remove]

        case .completed:
            var actions: [Self] = []
            if let thanksAction = thanksAction(for: item, ownUserId: ownUserId) {
                actions.append(thanksAction)
            }
            if canAddHelper {
                actions.append(.addHelper)
            }
            return actions + [.redo, .returnToIncomplete, .remove]

        case .notTodo:
            return []
        }
    }

    /// ありがとうに関して行えるアクション。送れず編集もできないなら`nil`
    private static func thanksAction(for item: HouseworkBoardItem, ownUserId: String) -> Self? {
        if item.canSendThanks(ownUserId: ownUserId) {
            return .sendThanks
        }
        guard item.canEditThanks(ownUserId: ownUserId) else { return nil }

        // コメントなしで送った場合は、まだメッセージを送っていないので書き足す扱いにする
        return item.sentThanks(ownUserId: ownUserId)?.comment == nil ? .addThanksMessage : .editThanksMessage
    }

}
