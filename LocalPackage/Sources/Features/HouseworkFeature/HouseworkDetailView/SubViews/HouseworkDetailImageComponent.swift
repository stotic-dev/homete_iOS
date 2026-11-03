//
//  HouseworkDetailImageComponent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事詳細の画像の欄（追加・拡大表示・削除と、無料プランのプレミアムプランへの案内を受け持つ）
struct HouseworkDetailImageComponent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.loginContext.account) var account
    @Environment(\.routeResolver) var router

    let item: HouseworkBoardItem
    /// 詳細画面と同じ通信中の表示を使う
    let loadingState: LoadingStateStore
    let onError: (any Error) -> Void

    @State var pickSource: HouseworkImagePickSource?
    @State var viewerInitialId: HouseworkImage.ID?
    @State var isPresentedPaywall = false
    @State var imageError: HouseworkImageError?

    var body: some View {
        HouseworkImageSectionContent(
            images: images,
            addState: addState,
            isCameraAvailable: CameraPicker.isAvailable,
            thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
            onTapImage: { imageId in viewerInitialId = imageId },
            onTapAdd: { source in pickSource = source },
            onTapPremium: { isPresentedPaywall = true },
            thumbnail: { image in
                HouseworkImageComponent(
                    source: .stored(image),
                    maxPixelSize: Self.thumbnailPixelSize,
                    contentMode: .fill
                )
            }
        )
        .houseworkImagePicker(source: $pickSource, maxSelectionCount: remainingCount) { originals in
            picked(originals)
        }
        .fullScreenCoverOnIOS(
            isPresented: .init(get: { viewerInitialId != nil }, set: { if !$0 { viewerInitialId = nil } })
        ) {
            if let viewerInitialId {
                HouseworkImageViewerScreen(
                    images: images,
                    initialId: viewerInitialId,
                    deletableIds: deletableIds,
                    onDelete: { image in try await delete(image) }
                )
            }
        }
        .fullScreenCoverOnIOS(isPresented: $isPresentedPaywall) {
            router.resolve(.paywall(step: .houseworkImage))
        }
        .houseworkImageErrorAlert($imageError)
    }

}

// MARK: - 表示内容

private extension HouseworkDetailImageComponent {

    /// サムネイルは1辺72pt前後なので、3倍の画面でもぼやけない大きさで読み込む
    static var thumbnailPixelSize: Int {
        300
    }

    var images: [HouseworkImage] {
        item.originalItem.images ?? []
    }

    var policy: HouseworkImagePolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    var addState: HouseworkImageAddState {
        .make(canAdd: item.originalItem.canAddImages, policy: policy, currentCount: images.count)
    }

    var remainingCount: Int {
        policy.addableCount(currentCount: images.count)
    }

    var deletableIds: Set<HouseworkImage.ID> {
        Set(images.filter { policy.canDelete($0, userId: account.id) }.map(\.id))
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkDetailImageComponent {

    func picked(_ originals: [@Sendable () async -> Data?]) {
        guard let cohabitantId = account.cohabitantId else { return }

        let target = item
        let uploaderId = account.id
        let policy = policy
        loadingState.task {
            do {
                let uploads = try await HouseworkImageUpload.make(loading: originals)
                guard !uploads.isEmpty else { return }
                try await houseworkListStore.addImages(
                    uploads,
                    target: target.originalItem,
                    cohabitantId: cohabitantId,
                    isRegistered: target.isRegistered,
                    uploaderId: uploaderId,
                    policy: policy,
                    step: .detail
                )
            } catch {
                handleError(error)
            }
        }
    }

    func delete(_ image: HouseworkImage) async throws {
        guard let cohabitantId = account.cohabitantId else { return }

        try await houseworkListStore.removeImage(
            image.id,
            target: item.originalItem,
            cohabitantId: cohabitantId,
            userId: account.id,
            policy: policy,
            step: .detail
        )
    }

    func handleError(_ error: any Error) {
        if let error = error as? HouseworkImageError {
            imageError = error
        } else {
            onError(error)
        }
    }

}
