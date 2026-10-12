//
//  ImplAccountInfoClient.swift
//

import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension AccountInfoClient {

    static let liveValue: AccountInfoClient = .init { account in
        try await FirestoreService.shared.insertOrUpdate(data: account) {
            $0.accountRef(id: account.id)
        }
    } fetch: { id in
        try await FirestoreService.shared.fetch {
            $0.accountRef(id: id)
        }
    } updateFcmToken: { accountId, fcmToken in
        try await FirestoreService.shared.commitBatch { firestore, batch in
            // フィールド名はFunctions（AccountFcmTokenFields.TOKEN）と合わせる
            batch.setData(["token": fcmToken], forDocument: firestore.accountFcmTokenRef(accountId: accountId))
            // 旧バージョンのアプリがAccount本体に書いたトークンを消す。同じグループのメンバーから読めてしまうため。
            // 旧アプリがいなくなったら、Functionsの旧フィールドへのフォールバックと一緒に外す（ADR-0044）
            batch.updateData(
                ["fcmToken": FieldValue.delete()],
                forDocument: firestore.accountRef(id: accountId)
            )
        }
    } addSnapshotListener: { listenerId, accountId in
        await FirestoreService.shared.addSnapshotListener(id: listenerId) {
            $0.accountRef(id: accountId)
        }
    } removeSnapshotListener: { listenerId in
        await FirestoreService.shared.removeSnapshotListener(id: listenerId)
    }

}
