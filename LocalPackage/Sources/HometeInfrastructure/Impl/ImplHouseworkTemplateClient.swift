import FirebaseFirestore
import HometeDomain

extension HouseworkTemplateClient {

    static let liveValue = HouseworkTemplateClient(
        fetchTemplates: { cohabitantId in
            try await FirestoreService.shared.fetch { firestore in
                firestore.houseworkTemplatesRef(cohabitantId: cohabitantId)
            }
        },
        fetchDays: { cohabitantId, templateId in
            try await FirestoreService.shared.fetch { firestore in
                firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
            }
        },
        upsertTemplate: { meta, cohabitantId in
            try await FirestoreService.shared.insertOrUpdate(data: meta) { firestore in
                firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(meta.templateId)
            }
        },
        updateDay: { day, templateId, cohabitantId, currentVersion in
            try await FirestoreService.shared.runTransaction { transaction in
                let metaRef = Firestore.firestore()
                    .houseworkTemplatesRef(cohabitantId: cohabitantId)
                    .document(templateId)
                let meta = try transaction.getDocument(metaRef).data(as: HouseworkTemplateMeta.self)
                guard meta.version == currentVersion else {
                    throw HouseworkTemplateError.versionConflict
                }
                let dayRef = Firestore.firestore()
                    .houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                    .document("\(day.dayOfWeek)")
                try transaction.setData(from: day, forDocument: dayRef)
                let updatedMeta = HouseworkTemplateMeta(
                    templateId: meta.templateId,
                    name: meta.name,
                    version: meta.version + 1
                )
                try transaction.setData(from: updatedMeta, forDocument: metaRef)
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
        removeListener: { id in
            await FirestoreService.shared.removeSnapshotListener(id: id)
        }
    )
}
