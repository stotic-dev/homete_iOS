//
//  CollectionPath.swift
//

import FirebaseFirestore

enum CollectionPath: String {

    case account = "Account"
    case cohabitant = "Cohabitant"
    case houseworks = "Houseworks"
    case dailyHouseworks = "DailyHouseworks"
    case houseworkTemplates = "HouseworkTemplates"
    case days = "Days"
    case editors = "Editors"
}

extension Firestore {

    func collection(path: CollectionPath) -> CollectionReference {

        return self.collection(path.rawValue)
    }
}
