//
//  HouseworkImageUseCase.swift
//  LocalPackage
//

import Foundation

/// 家事の画像の追加・削除
///
/// 画像の実体（Storage）と家事の参照（Firestore）は1つのトランザクションで書けないため、書く順番で食い違いを防ぐ（ADR-0067）。
/// - 追加: 実体を上げてから参照を書く。参照の書き込みに失敗したら、上げた実体を消す
/// - 削除: 参照を消してから実体を消す。実体を消すのに失敗しても、参照は戻さない
///
/// これにより、家事に参照だけが残って画像を表示できない状態は作らない。アプリが途中で終了すると参照の無い実体が残りうるが、
/// 家事が消えたときにバックエンドが家事のフォルダごと消す。
/// 同居人への通知は送らない。
public struct HouseworkImageUseCase: Sendable {

    private let houseworkClient: HouseworkClient
    private let imageClient: HouseworkImageClient
    private let analyticsClient: AnalyticsClient

    public init(
        houseworkClient: HouseworkClient,
        imageClient: HouseworkImageClient,
        analyticsClient: AnalyticsClient
    ) {
        self.houseworkClient = houseworkClient
        self.imageClient = imageClient
        self.analyticsClient = analyticsClient
    }

    /// 家事に画像を添える
    /// - Parameters:
    ///   - uploads: 添える画像。今ある画像の後ろに並べる
    ///   - current: 添える家事。登録済みの家事なら、呼び出し側が見つけた最新の記録を渡す
    ///   - isRegistered: 未登録（テンプレートから出しているだけ）の家事は、画像を添えた家事のドキュメントを新しく作る
    ///   - now: 未登録の家事のドキュメントを作るときの作成日時
    /// - Throws: 家事・プランの条件を満たさない場合は`HouseworkImageError`（何も書き込まない）
    func add( // swiftlint:disable:this function_parameter_count
        _ uploads: [HouseworkImageUpload],
        to current: HouseworkItem,
        isRegistered: Bool,
        cohabitantId: String,
        uploaderId: String,
        policy: HouseworkImagePolicy,
        now: Date,
        step: HouseworkAnalyticsStep
    ) async throws {
        do {
            let images = uploads.map {
                HouseworkImage.make(
                    id: $0.id,
                    houseworkId: current.id,
                    cohabitantId: cohabitantId,
                    uploaderId: uploaderId
                )
            }
            let updatedItem = try current.addingImages(images, policy: policy)
            try await upload(Array(zip(images, uploads.map(\.data))))
            do {
                if isRegistered {
                    try await houseworkClient.addImages(current.id, images, cohabitantId)
                } else {
                    try await houseworkClient.createItems([updatedItem.updateCreatedAt(now)], cohabitantId)
                }
            } catch {
                await discard(images)
                throw error
            }
        } catch {
            analyticsClient.log(.housework(.addImage(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.addImage(step: step, isSuccess: true)))
    }

    /// 家事から画像を1枚消す
    /// - Parameters:
    ///   - current: 消す画像を持つ家事。呼び出し側が見つけた最新の記録を渡す
    ///   - userId: 操作している本人のユーザーID
    /// - Throws: 消せない画像なら`HouseworkImageError.notDeletable`（何も書き込まない）
    func remove( // swiftlint:disable:this function_parameter_count
        _ imageId: HouseworkImage.ID,
        from current: HouseworkItem,
        cohabitantId: String,
        userId: String,
        policy: HouseworkImagePolicy,
        step: HouseworkAnalyticsStep
    ) async throws {
        // 同居人が先に消していたら、何もしない
        guard let image = current.images?.first(where: { $0.id == imageId }) else { return }

        do {
            _ = try current.removingImage(imageId, policy: policy, userId: userId)
            try await houseworkClient.removeImage(current.id, image, cohabitantId)
        } catch {
            analyticsClient.log(.housework(.removeImage(step: step, isSuccess: false)))
            throw error
        }
        analyticsClient.log(.housework(.removeImage(step: step, isSuccess: true)))
        await discard([image])
    }

    /// 画像を添えた家事をまとめて登録する
    ///
    /// 画像を上げてから、参照を付けた家事を`write`で書き込む。書き込みに失敗したら、上げた画像を消す。
    /// 画像を添えた家事があるときだけ、`add_image`を操作1回につき1イベント送る。
    /// - Parameter write: 参照を付けた家事を書き込む
    /// - Throws: 無料プランなら`HouseworkImageError.premiumRequired`、枚数を超えるなら`HouseworkImageError.limitExceeded`
    ///           （何も上げず、書き込まない）。上げる・書き込むのに失敗した場合は、上げた分を消してから投げる
    func register( // swiftlint:disable:this function_parameter_count
        _ newItems: [NewHouseworkEntry],
        cohabitantId: String,
        uploaderId: String,
        policy: HouseworkImagePolicy,
        step: HouseworkAnalyticsStep,
        write: @Sendable ([NewHouseworkEntry]) async throws -> Void
    ) async throws {
        let hasImages = newItems.contains { !$0.images.isEmpty }
        let logAdded = { (isSuccess: Bool) in
            guard hasImages else { return }
            analyticsClient.log(.housework(.addImage(step: step, isSuccess: isSuccess)))
        }
        var uploadedImages: [HouseworkImage] = []
        do {
            let (entries, targets) = try attachImages(
                to: newItems,
                cohabitantId: cohabitantId,
                uploaderId: uploaderId,
                policy: policy
            )
            try await upload(targets)
            uploadedImages = targets.map(\.0)
            try await write(entries)
        } catch {
            await discard(uploadedImages)
            logAdded(false)
            throw error
        }
        logAdded(true)
    }

    /// 上げた画像を消す。失敗しても家事の参照は無いので、ログに出すだけにする
    /// - Note: 消せずに残った実体は、家事が消えたときにバックエンドが家事のフォルダごと消す
    func discard(_ images: [HouseworkImage]) async {
        await withTaskGroup(of: Void.self) { group in
            for image in images {
                group.addTask {
                    do {
                        try await imageClient.delete(image.storagePath)
                    } catch {
                        print("Failed deleting housework image \(image.storagePath): \(error)")
                    }
                }
            }
        }
    }

}

private extension HouseworkImageUseCase {

    /// 登録する家事に画像の参照を付け、上げる画像と組にして返す
    func attachImages(
        to newItems: [NewHouseworkEntry],
        cohabitantId: String,
        uploaderId: String,
        policy: HouseworkImagePolicy
    ) throws -> (entries: [NewHouseworkEntry], targets: [(HouseworkImage, Data)]) {
        var entries: [NewHouseworkEntry] = []
        var targets: [(HouseworkImage, Data)] = []
        for entry in newItems {
            guard !entry.images.isEmpty else {
                entries.append(entry)
                continue
            }
            let images = entry.images.map {
                HouseworkImage.make(
                    id: $0.id,
                    houseworkId: entry.item.id,
                    cohabitantId: cohabitantId,
                    uploaderId: uploaderId
                )
            }
            try entries.append(.init(item: entry.item.addingImages(images, policy: policy), source: entry.source))
            targets += zip(images, entry.images.map(\.data))
        }
        return (entries, targets)
    }

    /// 画像をまとめて上げる。1枚でも失敗したら、上げようとした画像をすべて消してから投げる
    /// - Note: 失敗した時点で上げ終わっていた画像も、途中で止めた画像も区別せずに消す（無い画像を消しても成功になる）
    func upload(_ targets: [(HouseworkImage, Data)]) async throws {
        guard !targets.isEmpty else { return }
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (image, data) in targets {
                    group.addTask {
                        try await imageClient.upload(data, image.storagePath)
                    }
                }
                try await group.waitForAll()
            }
        } catch {
            await discard(targets.map(\.0))
            throw error
        }
    }

}
