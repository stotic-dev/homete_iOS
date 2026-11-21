//
//  OnboardingStep.swift
//  LocalPackage
//

/// アカウント登録からログイン完了までの間に順番に表示する画面
/// - Note: 環境やパートナー登録での選択によって不要になるステップ（通知の権限が決定済みの場合の`notificationPermission`など）があるため、
///         実際に表示するステップの並びは`allCases`ではなく`steps(isAnonymous:shouldGuideNotification:hasRegisteredPartner:)`で決める
public enum OnboardingStep: Hashable, CaseIterable, Sendable {

    /// アカウント（ニックネーム）登録
    case registration
    /// パートナー登録（招待・P2P・招待された・あとで）
    case partnerRegistration
    /// 匿名のアカウントをAppleアカウントと連携する（スキップできない）
    case accountLink
    /// プッシュ通知の権限リクエスト
    case notificationPermission
    /// プレミアムプランの特典説明（Paywallへの導線を持つ）
    case premiumIntroduction

}

public extension OnboardingStep {

    /// 案内するステップの並び
    ///
    /// 匿名のままパートナーと使い始めると、機種変更・アンインストールで共有した家事ごと失われる。
    /// そのためパートナー登録で行動した（招待を送った・P2Pで登録した・招待に参加した）匿名の人にだけ、その直後でApple連携を求める。
    /// 「あとで」を選んだ人は匿名のまま未参加ホームへ入れ、やることリストから連携してもらう。
    /// - Parameters:
    ///   - isAnonymous: オンボーディングを始めたときに匿名だったか。Appleでログインして始めた人には連携のステップを出さない
    ///   - shouldGuideNotification: 通知の権限が未決定か。決定済みならOSのダイアログが出ないため案内しない
    ///   - hasRegisteredPartner: パートナー登録で行動したか。パートナー登録を終えるまでは`false`
    static func steps(
        isAnonymous: Bool,
        shouldGuideNotification: Bool,
        hasRegisteredPartner: Bool
    ) -> [OnboardingStep] {
        allCases.filter { step in
            switch step {
            case .registration, .partnerRegistration, .premiumIntroduction:
                true

            case .accountLink:
                isAnonymous && hasRegisteredPartner

            case .notificationPermission:
                shouldGuideNotification
            }
        }
    }

    /// `steps`の並びの中で、このステップの次に案内するステップ。残りが無ければ`nil`
    /// - Note: 通知の権限の確認が後から返って案内が不要になったときなど、このステップが並びから外れていても、
    ///         `allCases`の順番で次を探す。並びの中の位置で探すと見つからず、先頭のステップへ戻ってしまう
    func next(in steps: [OnboardingStep]) -> OnboardingStep? {
        let order = Self.allCases
        guard let currentOrder = order.firstIndex(of: self) else { return nil }
        return steps.first { step in
            (order.firstIndex(of: step) ?? 0) > currentOrder
        }
    }

}
