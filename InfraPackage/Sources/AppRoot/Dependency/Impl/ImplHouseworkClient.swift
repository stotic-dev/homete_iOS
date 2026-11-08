//
//  ImplHouseworkClient.swift
//

import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension HouseworkClient {

    static let liveValue = HometeDomain.HouseworkClient { item, cohabitantId in
        // 保持期限（expiredAt）はCloud Functionsだけが書くため、アプリが書くフィールドだけを上書きする
        try await FirestoreService.shared.insertOrUpdate(data: item, fieldNames: HouseworkItem.writtenFieldNames) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } insertOrUpdateItemsHandler: { items, cohabitantId in
        try await FirestoreService.shared.batchInsertOrUpdate(
            data: items,
            fieldNames: HouseworkItem.writtenFieldNames
        ) { firestore, item in
            firestore
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } removeItemHandler: { item, cohabitantId in
        try await FirestoreService.shared.delete {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } upsertThanksHandler: { houseworkId, senderId, thanks, cohabitantId in
        try await FirestoreService.shared.update(fieldPath: "thanks.\(senderId)", value: thanks) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(houseworkId)
        }
    } upsertThanksBatchHandler: { houseworkIds, senderId, thanks, cohabitantId in
        try await FirestoreService.shared.batchUpdate(fieldPath: "thanks.\(senderId)", value: thanks) { firestore in
            houseworkIds.map {
                firestore
                    .houseworkListRef(id: cohabitantId)
                    .document($0)
            }
        }
    } updateMemoHandler: { houseworkId, memo, cohabitantId in
        try await FirestoreService.shared.update(fieldPath: "memo", value: memo) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(houseworkId)
        }
    } createItemsHandler: { items, cohabitantId in
        try await FirestoreService.shared.batchInsertOrUpdate(
            data: items,
            fieldNames: HouseworkItem.creationFieldNames
        ) { firestore, item in
            firestore
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } addImagesHandler: { houseworkId, images, cohabitantId in
        try await FirestoreService.shared.arrayUnion(fieldPath: "images", elements: images) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(houseworkId)
        }
    } createItemOrAddImagesHandler: { item, images, cohabitantId in
        try await FirestoreService.shared.insertOrArrayUnion(
            data: item,
            fieldNames: HouseworkItem.creationFieldNames,
            arrayFieldPath: "images",
            elements: images
        ) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(item.id)
        }
    } removeImageHandler: { houseworkId, image, cohabitantId in
        try await FirestoreService.shared.arrayRemove(fieldPath: "images", elements: [image]) {
            $0
                .houseworkListRef(id: cohabitantId)
                .document(houseworkId)
        }
    } snapshotListenerHandler: { id, cohabitantId, anchorDate, offset in
        let targetDateList = HouseworkIndexedDate.calcTargetPeriod(
            anchorDate: anchorDate,
            offsetDays: offset,
            calendar: .autoupdatingCurrent
        )

        return await FirestoreService.shared.addSnapshotListener(id: id) {
            $0.houseworkListRef(id: cohabitantId)
                .whereField("indexedDate.value", in: targetDateList)
        }
    } removeListenerHandler: { id in
        await FirestoreService.shared.removeSnapshotListener(id: id)
    } fetchItemsHandler: { cohabitantId, from, to in
        try await FirestoreService.shared.fetchSkippingUndecodable {
            $0.houseworkListRef(id: cohabitantId)
                .whereField("indexedDate.value", isGreaterThanOrEqualTo: from)
                .whereField("indexedDate.value", isLessThanOrEqualTo: to)
        }
    }

}
