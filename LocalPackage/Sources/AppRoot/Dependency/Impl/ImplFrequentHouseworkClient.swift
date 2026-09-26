//
//  ImplFrequentHouseworkClient.swift
//  LocalPackage
//

import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension FrequentHouseworkClient {

    static let liveValue = FrequentHouseworkClient(
        addItemsSnapshotListener: { id, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.frequentHouseworksRef(cohabitantId: cohabitantId)
                }
            )
        },
        addCategoriesSnapshotListener: { id, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.frequentHouseworkCategoriesRef(cohabitantId: cohabitantId)
                }
            )
        },
        upsertItems: { items, cohabitantId in
            try await FirestoreService.shared.batchInsertOrUpdate(data: items) { firestore, item in
                firestore.frequentHouseworksRef(cohabitantId: cohabitantId).document(item.id)
            }
        },
        deleteItem: { id, cohabitantId in
            try await FirestoreService.shared.delete { firestore in
                firestore.frequentHouseworksRef(cohabitantId: cohabitantId).document(id)
            }
        },
        upsertCategories: { categories, cohabitantId in
            try await FirestoreService.shared.batchInsertOrUpdate(data: categories) { firestore, category in
                firestore.frequentHouseworkCategoriesRef(cohabitantId: cohabitantId).document(category.id)
            }
        },
        deleteCategory: { id, cohabitantId in
            try await FirestoreService.shared.delete { firestore in
                firestore.frequentHouseworkCategoriesRef(cohabitantId: cohabitantId).document(id)
            }
        },
        removeListener: { id in
            await FirestoreService.shared.removeSnapshotListener(id: id)
        }
    )

}
