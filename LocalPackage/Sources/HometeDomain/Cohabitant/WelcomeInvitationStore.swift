//
//  WelcomeInvitationStore.swift
//  LocalPackage
//

import Observation

/// ログイン前の説明画面に出す招待の案内
public enum WelcomeInvitation: Equatable, Sendable {

    /// 招待を出さない（招待リンクを開いていない、または取得できなかった）
    case none
    /// 招待が届いている
    /// - Parameter inviterName: 招待者の表示名。名前が無い招待ならnil
    case invited(inviterName: String?)

}

/// 招待リンクを開いてから起動した人に、説明画面で誰から招待が届いているかを出すStore
///
/// ログイン前に招待者名を取るため、未認証でも呼べる`fetchcohabitantinvitation`を使う。
/// 取得に失敗した・無効な招待のときは案内を出さず、通常の説明画面にする（参加の可否はログイン後の参加確認で伝える）。
@MainActor
@Observable
public final class WelcomeInvitationStore {

    public private(set) var invitation: WelcomeInvitation = .none

    // MARK: Dependencies

    private let cohabitantInvitationClient: CohabitantInvitationClient

    public init(cohabitantInvitationClient: CohabitantInvitationClient = .previewValue) {
        self.cohabitantInvitationClient = cohabitantInvitationClient
    }

    /// 保持している招待トークンから、招待の案内を読み込む
    /// - Parameter token: `PendingInvitationStore`が保持している招待トークン。無ければ案内を出さない
    public func load(token: String?) async {
        guard let token else {
            invitation = .none
            return
        }

        do {
            let summary = try await cohabitantInvitationClient.fetch(token)
            // 取得中に別のリンクが開かれた（.task(id:)がキャンセルされた）場合は、新しいトークンの結果に任せる
            guard !Task.isCancelled else { return }
            let inviterName = summary.inviterName.flatMap { $0.isEmpty ? nil : $0 }
            invitation = .invited(inviterName: inviterName)
        } catch {
            guard !Task.isCancelled else { return }
            invitation = .none
        }
    }

}
