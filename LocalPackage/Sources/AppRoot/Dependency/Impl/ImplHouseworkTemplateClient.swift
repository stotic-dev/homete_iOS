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
        updateDays: { days, templateId, cohabitantId, currentVersion in
            try await FirestoreService.shared.runTransaction { transaction in
                let metaRef = Firestore.firestore()
                    .houseworkTemplatesRef(cohabitantId: cohabitantId)
                    .document(templateId)
                let metaDocument = try transaction
                    .getDocument(metaRef)
                    .data(as: HouseworkTemplateMetaDocument.self)
                guard metaDocument.version == currentVersion else {
                    throw HouseworkTemplateError.versionConflict
                }
                let daysRef = Firestore.firestore()
                    .houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                for day in days {
                    let dayRef = daysRef.document("\(day.dayOfWeek.rawValue)")
                    try transaction.setData(from: day, forDocument: dayRef)
                }
                let updatedDocument = HouseworkTemplateMetaDocument(
                    templateId: metaDocument.templateId,
                    name: metaDocument.name,
                    version: metaDocument.version + 1
                )
                try transaction.setData(from: updatedDocument, forDocument: metaRef)
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
            await FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
            }
        },
        addEditorsSnapshotListener: { id, templateId, cohabitantId in
            await FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                firestore.houseworkTemplateEditorsRef(cohabitantId: cohabitantId, templateId: templateId)
            }
        },
        addMetaVersionSnapshotListener: { id, templateId, cohabitantId in
            let documentStream: AsyncStream<HouseworkTemplateMetaDocument?> = await FirestoreService
                .shared
                .addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(templateId)
                }
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
