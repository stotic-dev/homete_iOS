//
//  FirestoreExtensionForReferencePath.swift
//

import FirebaseFirestore

public extension Firestore {

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

    /// テンプレート一覧コレクションの参照を取得する
    func houseworkTemplatesRef(cohabitantId: String) -> CollectionReference {
        cohabitantRef(id: cohabitantId)
            .collection(CollectionPath.houseworkTemplates.rawValue)
    }

    /// 特定テンプレートの Days コレクションの参照を取得する
    func houseworkTemplateDaysRef(cohabitantId: String, templateId: String) -> CollectionReference {
        houseworkTemplatesRef(cohabitantId: cohabitantId)
            .document(templateId)
            .collection(CollectionPath.days.rawValue)
    }

    /// 特定テンプレートの Editors コレクションの参照を取得する
    func houseworkTemplateEditorsRef(cohabitantId: String, templateId: String) -> CollectionReference {
        houseworkTemplatesRef(cohabitantId: cohabitantId)
            .document(templateId)
            .collection(CollectionPath.editors.rawValue)
    }

}
