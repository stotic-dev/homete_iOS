import FirebaseFirestore
import HometeDomain
import HometeInfrastructure

extension HouseworkTemplateClient {

    static let liveValue = HouseworkTemplateClient(
        fetchTemplates: { cohabitantId in
            let documents: [HouseworkTemplateMetaDocument] = try await FirestoreService.shared
                .fetch { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId)
                }
            return documents.map { HouseworkTemplateMeta(templateId: $0.templateId, name: $0.name) }
        },
        fetchDays: { cohabitantId, templateId in
            try await FirestoreService.shared.fetch { firestore in
                firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
            }
        },
        upsertTemplate: { meta, cohabitantId in
            let document = HouseworkTemplateMetaDocument(
                templateId: meta.templateId,
                name: meta.name,
                version: 0
            )
            try await FirestoreService.shared.insertOrUpdate(data: document) { firestore in
                firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(meta.templateId)
            }
        },
        fetchMonthlyItems: { cohabitantId, templateId in
            let documents: [LenientDecoded<HouseworkTemplateMonthlyItem>] = try await FirestoreService.shared
                .fetch { firestore in
                    firestore.houseworkTemplateMonthlyItemsRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            return documents.compactMap(\.value)
        },
        updateTemplate: { update, templateId, cohabitantId, currentVersion in
            try await FirestoreService.shared.runTransaction { transaction in
                let firestore = Firestore.firestore()
                let metaRef = firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(templateId)
                let metaDocument = try transaction
                    .getDocument(metaRef)
                    .data(as: HouseworkTemplateMetaDocument.self)
                guard metaDocument.version == currentVersion else {
                    throw HouseworkTemplateError.versionConflict
                }
                let daysRef = firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                for day in update.days {
                    try transaction.setData(from: day, forDocument: daysRef.document("\(day.dayOfWeek.rawValue)"))
                }
                let monthlyItemsRef = firestore.houseworkTemplateMonthlyItemsRef(
                    cohabitantId: cohabitantId,
                    templateId: templateId
                )
                for monthlyItem in update.upsertedMonthlyItems {
                    try transaction.setData(from: monthlyItem, forDocument: monthlyItemsRef.document(monthlyItem.id.id))
                }
                for deletedId in update.deletedMonthlyItemIds {
                    transaction.deleteDocument(monthlyItemsRef.document(deletedId.id))
                }
                try transaction.setData(from: metaDocument.incrementedVersion(), forDocument: metaRef)
            }
        },
        appendItem: { item, recurrence, templateId, cohabitantId in
            try await FirestoreService.shared.runTransaction { transaction in
                let firestore = Firestore.firestore()
                let metaRef = firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(templateId)
                // トランザクションでは読み取りを書き込みより先に済ませる必要がある
                let metaDocument = try transaction
                    .getDocument(metaRef)
                    .data(as: HouseworkTemplateMetaDocument.self)

                switch recurrence {
                case let .weekly(daysOfWeek):
                    let daysRef = firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                    let currentDays = try daysOfWeek.map { dayOfWeek in
                        let snapshot = try transaction.getDocument(daysRef.document("\(dayOfWeek.rawValue)"))
                        return snapshot.exists
                            ? try snapshot.data(as: HouseworkTemplateDay.self)
                            : HouseworkTemplateDay(dayOfWeek: dayOfWeek, items: [])
                    }
                    for day in currentDays {
                        let appendedDay = HouseworkTemplateDay(dayOfWeek: day.dayOfWeek, items: day.items + [item])
                        try transaction.setData(
                            from: appendedDay,
                            forDocument: daysRef.document("\(day.dayOfWeek.rawValue)")
                        )
                    }

                case let .monthly(rule):
                    let monthlyItem = HouseworkTemplateMonthlyItem(item: item, rule: rule)
                    try transaction.setData(
                        from: monthlyItem,
                        forDocument: firestore
                            .houseworkTemplateMonthlyItemsRef(cohabitantId: cohabitantId, templateId: templateId)
                            .document(item.id.id)
                    )
                }
                try transaction.setData(from: metaDocument.incrementedVersion(), forDocument: metaRef)
            }
        },
        upsertEditor: { editor, templateId, cohabitantId in
            try await FirestoreService.shared.insertOrUpdate(data: editor) { firestore in
                firestore.houseworkTemplateEditorsRef(cohabitantId: cohabitantId, templateId: templateId)
                    .document(editor.userId)
            }
        },
        removeEditor: { userId, templateId, cohabitantId in
            try await FirestoreService.shared.delete { firestore in
                firestore.houseworkTemplateEditorsRef(cohabitantId: cohabitantId, templateId: templateId)
                    .document(userId)
            }
        },
        addDaysSnapshotListener: { id, templateId, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            )
        },
        addMonthlyItemsSnapshotListener: { id, templateId, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplateMonthlyItemsRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            )
        },
        addTemplatesSnapshotListener: { id, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId)
                }
            )
        },
        addEditorsSnapshotListener: { id, templateId, cohabitantId in
            await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplateEditorsRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            )
        },
        addMetaVersionSnapshotListener: { id, templateId, cohabitantId in
            let documentStream: AsyncStream<HouseworkTemplateMetaDocument?> = await bridgingToNonThrowing(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(templateId)
                }
            )
            let (versionStream, continuation) = AsyncStream<Int>.makeStream()
            Task {
                for await document in documentStream {
                    guard let document else { continue }
                    continuation.yield(document.version)
                }
                continuation.finish()
            }
            return versionStream
        },
        removeListener: { id in
            await FirestoreService.shared.removeSnapshotListener(id: id)
        }
    )

}

private extension HouseworkTemplateMetaDocument {

    func incrementedVersion() -> Self {
        .init(templateId: templateId, name: name, version: version + 1)
    }

}

/// デコードに失敗したドキュメントを`nil`として扱うラッパー
///
/// `FirestoreService.fetch`は1件でもデコードに失敗すると全体が失敗する。毎月の家事は将来`rule.type`を
/// 増やす想定なので、旧バージョンのアプリが新しい種類のルールを読んでも他の家事まで読めなくならないようにする（ADR-0020）。
/// SnapshotListener側は`FirestoreService.addSnapshotListener`が元から1件ずつ`try?`でデコードしているので、このラッパーは不要。
/// 一方で`appendItem`の`Days`の読み取りは意図的に厳格にしている（読めなかった既存の家事を空として上書きしないため）。
private struct LenientDecoded<Value: Decodable & Sendable>: Decodable {

    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }

}
