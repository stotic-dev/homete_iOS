//
//  ImplSentInvitationClient.swift
//

import Foundation
import HometeDomain

extension SentInvitationClient {

    /// 1件だけを`UserDefaults`にJSONで保存する
    ///
    /// 読み出せない（形式が変わった・壊れた）場合は送っていないものとして扱い、未参加ホームに「参加を待っています」を出さない。
    static let liveValue: SentInvitationClient = .init(
        load: {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }

            return try? JSONDecoder().decode(SentCohabitantInvitation.self, from: data)
        },
        save: { invitation in
            guard let data = try? JSONEncoder().encode(invitation) else { return }

            UserDefaults.standard.set(data, forKey: storageKey)
        },
        clear: {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    )

}

private extension SentInvitationClient {

    static let storageKey = "sentCohabitantInvitation"

}
