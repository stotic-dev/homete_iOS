//
//  OnboardingStep.swift
//  LocalPackage
//

/// アカウント登録からログイン完了までの間に順番に表示する画面
/// - Note: 環境によって不要になるステップ（通知の権限が決定済みの場合の`notificationPermission`など）があるため、
///         実際に表示するステップの並びは`allCases`ではなくフロー側が保持する
enum OnboardingStep: Hashable, CaseIterable {

    /// アカウント（ニックネーム）登録
    case registration
    /// プレミアムプランの特典説明（Paywallへの導線を持つ）
    case premiumIntroduction
    /// プッシュ通知の権限リクエスト
    case notificationPermission

}
