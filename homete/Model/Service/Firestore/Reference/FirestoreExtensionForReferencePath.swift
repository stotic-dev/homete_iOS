//
//  FirestoreExtensionForReferencePath.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/04.
//

import FirebaseFirestore

extension Firestore {
    
    /// アカウントの参照を取得する
    func accountRef(id: String) -> DocumentReference {
        
        return self
            .collection(CollectionPath.account.rawValue)
            .document(id)
    }
    
    /// 同居人の参照を取得する
    func cohabitantRef(id: String) -> DocumentReference {
        
        return self
            .collection(CollectionPath.cohabitant.rawValue)
            .document(id)
    }
    
    /// 家事コレクションの参照を取得する
    func houseworkListRef(id: String) -> CollectionReference {
        
        return self.cohabitantRef(id: id)
            .collection(CollectionPath.houseworks.rawValue)
    }
}
