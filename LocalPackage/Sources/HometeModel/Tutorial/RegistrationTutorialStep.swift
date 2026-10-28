//
//  RegistrationTutorialStep.swift
//  LocalPackage
//

/// グループ登録の直後に出す、導線を案内するチュートリアルのステップ
/// - Note: 並び順がそのまま表示順になる。操作はさせず「ここでは〇〇ができる」と伝えるだけにとどめる
public enum RegistrationTutorialStep: String, TutorialStep {

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
