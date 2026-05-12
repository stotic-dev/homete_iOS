//
//  CollectionPath.swift
//

import FirebaseFirestore

public enum CollectionPath: String {

    case account = "Account"
    case cohabitant = "Cohabitant"
    case houseworks = "Houseworks"
    case dailyHouseworks = "DailyHouseworks"
    case houseworkTemplates = "HouseworkTemplates"
    case days = "Days"
    case editors = "Editors"

}

public extension Firestore {

    func collection(path: CollectionPath) -> CollectionReference {
        collection(path.rawValue)
    }

}
