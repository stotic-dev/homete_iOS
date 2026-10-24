//
//  AppIntentAnalyticsAction.swift
//  LocalPackage
//

/// 実行したApp Intent
public enum AppIntentAnalyticsIntent: String, Equatable, Sendable, CaseIterable {

    /// アプリを開かずに家事を完了にする
    case completeHousework = "complete_housework"
    /// アプリを開いて家事の完了シートを出す
    case openHouseworkComplete = "open_housework_complete"
    /// アプリを開かずにありがとうを伝える
    case sendThanks = "send_thanks"
    /// 今月のがんばりをSiriの結果に出す
    case showContributionSummary = "show_contribution_summary"
    /// アプリを開いてがんばりの分析画面を出す
    case openContributionAnalytics = "open_contribution_analytics"
    /// アプリを開かずに、やった家事を記録する（今日の家事に無ければ新しく作って完了にする）
    case recordHousework = "record_housework"
    /// アプリを開かずに、これからやる家事を今日の家事に登録する
    case registerHousework = "register_housework"

}

/// App Intentを実行した結果
/// - Note: GA上でそのまま読める値にするため、真偽値ではなく意味のある文字列にする
public enum AppIntentAnalyticsResult: String, Equatable, Sendable, CaseIterable {

    /// 実行できた
    case success
    /// 対象の家事が見つからなかった・ありがとうを伝えられる家事が無かった
    case notFound = "not_found"
    /// 家事がすでに完了していた
    case alreadyCompleted = "already_completed"
    /// 登録しようとした家事が、今日の家事にもう未完了である
    case alreadyRegistered = "already_registered"
    /// 補足のメモが、プランで書ける文字数を超えていた
    case memoLimitExceeded = "memo_limit_exceeded"
    /// 確認に「いいえ」と答え、記録・登録しなかった
    case cancelled
    /// 通信できず、書き込みを端末に保存した（オンラインになったら反映される）
    case pendingSync = "pending_sync"
    /// ログインしていなかった
    case notLoggedIn = "not_logged_in"
    /// 同居人グループに所属していなかった
    case noCohabitant = "no_cohabitant"
    /// 強制アップデートが必要なバージョンだった
    case updateRequired = "update_required"
    /// 通信などで失敗した
    case failure

}

public extension AppIntentAnalyticsResult {

    init(_ failure: AppIntentFailure) {
        switch failure {
        case .notLoggedIn:
            self = .notLoggedIn

        case .noCohabitant:
            self = .noCohabitant

        case .updateRequired:
            self = .updateRequired
        }
    }

}
