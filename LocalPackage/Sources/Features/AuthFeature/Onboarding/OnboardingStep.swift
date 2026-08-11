//
//  OnboardingStep.swift
//  LocalPackage
//

/// アカウント登録からログイン完了までの間に順番に表示する画面
enum OnboardingStep: Hashable {

    /// アカウント（ニックネーム）登録
    case registration
    /// プレミアムプランの特典説明（Paywallへの導線を持つ）
    case premiumIntroduction
    /// プッシュ通知の権限リクエスト
    case notificationPermission

}
