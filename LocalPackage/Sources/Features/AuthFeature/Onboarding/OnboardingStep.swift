//
//  OnboardingStep.swift
//  LocalPackage
//

/// アカウント登録からログイン完了までの間に順番に表示する画面
enum OnboardingStep: Hashable, CaseIterable {

    /// アカウント（ニックネーム）登録
    case registration
    /// プレミアムプランの特典説明（Paywallへの導線を持つ）
    case premiumIntroduction
    /// プッシュ通知の権限リクエスト
    case notificationPermission

}

extension OnboardingStep {

    /// 先頭から数えた順番（1始まり）
    var order: Int {
        (Self.allCases.firstIndex(of: self) ?? 0) + 1
    }

}
