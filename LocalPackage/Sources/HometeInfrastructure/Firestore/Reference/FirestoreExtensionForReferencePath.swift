//
//  FirestoreExtensionForReferencePath.swift
//

import FirebaseFirestore

extension Firestore {

    /// アカウントの参照を取得する
    func accountRef(id: String) -> DocumentReference {
        collection(CollectionPath.account.rawValue)
            .document(id)
    }

    /// 同居人の参照を取得する
    func cohabitantRef(id: String) -> DocumentReference {
        collection(CollectionPath.cohabitant.rawValue)
            .document(id)
    }

    /// 家事コレクションの参照を取得する
    func houseworkListRef(id: String) -> CollectionReference {
        cohabitantRef(id: id)
            .collection(CollectionPath.houseworks.rawValue)
    }

}
