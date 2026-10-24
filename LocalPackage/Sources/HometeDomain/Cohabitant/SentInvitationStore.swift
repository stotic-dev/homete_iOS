//
//  SentInvitationStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// 最後に送った招待を持つStore
///
/// 招待リンクを送るのはオンボーディング・同居人登録画面・設定の3か所なので、保存はここにまとめる。
/// 未参加ホームは、送った招待が有効期限内なら「参加を待っています」を出し、同じ招待を送り直せるようにする。
/// 相手が参加すると`Account.cohabitantId`が入りホームが切り替わるため、参加の検知には使わない。
@MainActor
@Observable
public final class SentInvitationStore {

    /// 最後に送った招待
    public private(set) var sentInvitation: SentCohabitantInvitation?

    @ObservationIgnored private var hasLoaded = false

    // MARK: Dependencies

    private let sentInvitationClient: SentInvitationClient

    public init(sentInvitationClient: SentInvitationClient = .previewValue) {
        self.sentInvitationClient = sentInvitationClient
    }

    /// 端末に保存した招待を読み出す
    /// - Note: 保存は起動をまたいで残るため、最初の1回だけ読み出す
    public func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        let loaded = await sentInvitationClient.load()
        // 読み出している間に送った招待の方が新しいため、上書きしない
        if sentInvitation == nil {
            sentInvitation = loaded
        }
    }

    /// 招待を送ったことを記録する
    /// - Note: 共有シートで共有を完了したときに呼ぶ。発行しただけ（共有をキャンセルした）では送ったことにしない
    public func save(_ invitation: CohabitantInvitation, accountId: String) async {
        let sent = SentCohabitantInvitation(
            accountId: accountId,
            token: invitation.token,
            expiresAt: invitation.expiresAt
        )
        sentInvitation = sent
        await sentInvitationClient.save(sent)
    }

    /// 記録した招待を消す
    /// - Note: ログアウト・退会で呼ぶ
    public func clear() async {
        sentInvitation = nil
        await sentInvitationClient.clear()
    }

    /// 相手の参加を待っている招待
    /// - Returns: そのアカウントが送った、有効期限内の招待。無ければ`nil`
    public func waitingInvitation(accountId: String, now: Date) -> CohabitantInvitation? {
        guard let sentInvitation,
              sentInvitation.accountId == accountId,
              sentInvitation.expiresAt > now else { return nil }

        return CohabitantInvitation(
            token: sentInvitation.token,
            // 送り直すときに使うのはトークンだけなので、グループIDは持たない
            cohabitantId: nil,
            expiresAt: sentInvitation.expiresAt
        )
    }

}
