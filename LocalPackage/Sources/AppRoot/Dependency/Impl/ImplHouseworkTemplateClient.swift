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
            await bridgingToResult(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplateDaysRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            )
        },
        addTemplatesSnapshotListener: { id, cohabitantId in
            await bridgingToResult(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId)
                }
            )
        },
        addEditorsSnapshotListener: { id, templateId, cohabitantId in
            await bridgingToResult(
                FirestoreService.shared.addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplateEditorsRef(cohabitantId: cohabitantId, templateId: templateId)
                }
            )
        },
        addMetaVersionSnapshotListener: { id, templateId, cohabitantId in
            let documentStream: AsyncThrowingStream<HouseworkTemplateMetaDocument?, Error> = await FirestoreService
                .shared
                .addSnapshotListener(id: id) { firestore in
                    firestore.houseworkTemplatesRef(cohabitantId: cohabitantId).document(templateId)
                }
            return bridgingToResult(documentStream) { document in
                document?.version
            }
        },
        removeListener: { id in
            await FirestoreService.shared.removeSnapshotListener(id: id)
        }
    )

}

/// `FirestoreService`が返す`AsyncThrowingStream`を、失敗を値として流す`AsyncStream`へ変換する
///
/// - Note: 購読側でエラーを扱えるようにしつつ、ストリーム自体は終了させない。
///         エラーで終了させてしまうと、再購読するまで以降の値が一切届かなくなるため。
/// - Parameter transform: 受け取った値を購読側の要素へ変換する。`nil`を返した要素は読み飛ばす。
private func bridgingToResult<Input: Sendable, Output: Sendable>(
    _ throwingStream: AsyncThrowingStream<Input, Error>,
    transform: @escaping @Sendable (Input) -> Output?
) -> AsyncStream<Result<Output, DomainError>> {
    AsyncStream { continuation in
        let task = Task {
            do {
                for try await value in throwingStream {
                    guard let transformed = transform(value) else { continue }
                    continuation.yield(.success(transformed))
                }
                continuation.finish()
            } catch {
                print("occurred error at addSnapshotListener(type: \(Input.self), error: \(error))")
                continuation.yield(.failure(DomainError.make(error) ?? .other))
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

private func bridgingToResult<Output: Sendable>(
    _ throwingStream: AsyncThrowingStream<Output, Error>
) -> AsyncStream<Result<Output, DomainError>> {
    bridgingToResult(throwingStream) { $0 }
}
