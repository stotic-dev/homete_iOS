//
//  AppScreen.swift
//  LocalPackage
//

/// `screen_view`イベントで送信する画面
/// - Note: GA4の予約パラメータ`screen_name`にそのまま載せるため、値は`snake_case`で定義する。
///         画面内の状態遷移（同居人登録のスキャン中など）は画面として分けず、機能ごとのイベントの`action`で区別する
public enum AppScreen: String, Equatable, Sendable, CaseIterable {

    /// 起動中のスプラッシュ
    case launch
    /// Sign in with Appleのログイン画面
    case login
    /// アカウント登録画面
    case registrationAccount = "registration_account"
    /// オンボーディングのプレミアムプラン特典説明
    case onboardingPremiumIntroduction = "onboarding_premium_introduction"
    /// オンボーディングのプッシュ通知権限ガイド
    case onboardingNotificationPermission = "onboarding_notification_permission"
    /// 課金プランのPaywall
    case paywall
    /// 同居人グループ登録済みのダッシュボード
    case dashboard
    /// 同居人グループ未登録のダッシュボード
    case dashboardNotRegistered = "dashboard_not_registered"
    /// 同居人グループの登録画面
    case cohabitantRegistration = "cohabitant_registration"
    /// 招待リンクからの同居人グループ参加画面
    case cohabitantJoin = "cohabitant_join"
    /// 同居人グループ登録の完了画面
    case cohabitantCompletion = "cohabitant_completion"
    /// 未完了の家事一覧
    case incompleteHouseworkList = "incomplete_housework_list"
    /// 家事の貢献度分析
    case contributionAnalytics = "contribution_analytics"
    /// 家事ボード
    case houseworkBoard = "housework_board"
    /// 家事の詳細
    case houseworkDetail = "housework_detail"
    /// 家事の登録
    case houseworkRegister = "housework_register"
    /// 家事の承認
    case houseworkApproval = "housework_approval"
    /// 家事テンプレートの一覧
    case houseworkTemplate = "housework_template"
    /// 家事テンプレートの詳細
    case houseworkTemplateDetail = "housework_template_detail"
    /// 家事テンプレートの編集
    case houseworkTemplateEdit = "housework_template_edit"
    /// 設定画面
    case setting
    /// サブスクリプションの管理画面
    case subscriptionManagement = "subscription_management"
    /// 設定画面から開くプッシュ通知権限ガイド
    case settingNotificationPermission = "setting_notification_permission"
    /// ライセンス一覧
    case licenseList = "license_list"
    /// ライセンス詳細
    case licenseDetail = "license_detail"

}

public extension AppScreen {

    /// `screen_view`イベントの`screen_name`パラメータに載せる値
    var screenName: String {
        rawValue
    }

}
