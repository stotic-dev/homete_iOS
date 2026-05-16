//
//  CollectionPath.swift
//

#if os(iOS)
    import FirebaseFirestore

    enum CollectionPath: String {

        case account = "Account"
        case cohabitant = "Cohabitant"
        case houseworks = "Houseworks"
        case dailyHouseworks = "DailyHouseworks"

    }

    extension Firestore {

        func collection(path: CollectionPath) -> CollectionReference {
            collection(path.rawValue)
        }

    }
#endif
