//
//  IntentDonationClient.swift
//  LocalPackage
//

/// アプリの中でした操作をOSに伝え（ドネーション）、Siri・Spotlight・ロック画面で同じ操作を提案してもらう
///
/// 実装はApp Intentsを持つ`HometeAppIntents`に置き、`HometeDomain`をApp Intentsに依存させない。
/// ドネーションしてよいのは、ユーザー自身がアプリの中で1件だけ操作したときに限る。
/// 一括操作・Intent経由の実行・同居人の操作の受信でドネーションすると、OSの学習を誤らせる。
public struct IntentDonationClient: Sendable {

    /// 家事を完了にした。家事は日ごとに別のIDなので、日をまたいでも変わらない家事の名前で伝える
    public let donateCompleteHousework: @Sendable (_ houseworkTitle: String) -> Void
    /// ありがとうを伝えた。送った家事は翌日には候補にならないため、家事は伝えない
    public let donateSendThanks: @Sendable () -> Void
    /// がんばりの分析を見た
    public let donateContributionSummary: @Sendable () -> Void

    public init(
        donateCompleteHousework: @Sendable @escaping (_ houseworkTitle: String) -> Void = { _ in },
        donateSendThanks: @Sendable @escaping () -> Void = {},
        donateContributionSummary: @Sendable @escaping () -> Void = {}
    ) {
        self.donateCompleteHousework = donateCompleteHousework
        self.donateSendThanks = donateSendThanks
        self.donateContributionSummary = donateContributionSummary
    }

}

public extension IntentDonationClient {

    static let previewValue: IntentDonationClient = .init()

}
