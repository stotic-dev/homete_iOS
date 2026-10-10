//
//  RegistrationTutorialStep.swift
//  LocalPackage
//

/// グループ登録の直後に出す、導線を案内するチュートリアルのステップ
/// - Note: 並び順がそのまま表示順になる。操作はさせず「ここでは〇〇ができる」と伝えるだけにとどめる
public enum RegistrationTutorialStep: String, CaseIterable, Equatable, Sendable {

    /// ダッシュボードタブ。今日の家事の進み具合と貢献度
    case dashboard
    /// 家事タブ。家事の登録
    case housework
    /// 家事を完了にする方法（詳細画面と長押しのメニュー）
    case houseworkComplete = "housework_complete"
    /// 完了した家事へのありがとう。送ると相手に通知が届く
    case thanks
    /// 複数の家事を選んで、まとめて完了やありがとうをする
    case bulkAction = "bulk_action"
    /// 家事テンプレートの入口
    case houseworkTemplate = "housework_template"

}

public extension RegistrationTutorialStep {

    /// 何番目のステップか（0始まり）
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// 次のステップ。最後のステップならnil
    var next: Self? {
        let nextIndex = index + 1
        return Self.allCases.indices.contains(nextIndex) ? Self.allCases[nextIndex] : nil
    }

    /// 前のステップ。最初のステップならnil
    var previous: Self? {
        let previousIndex = index - 1
        return Self.allCases.indices.contains(previousIndex) ? Self.allCases[previousIndex] : nil
    }

}
