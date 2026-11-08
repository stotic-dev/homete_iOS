//
//  HouseworkImageViewerScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import HouseworkFeatureUI
import SwiftUI

/// 家事に添えた画像の拡大表示（消すときの確認と保存を受け持つ）
struct HouseworkImageViewerScreen: View {

    @Environment(\.dismiss) var dismiss
    @LoadingState var loadingState
    @CommonError var commonErrorContent

    /// 家事に添えてある画像。同居人が消したときにも追従できるよう、呼び出し側の最新の家事から渡す
    let images: [HouseworkImage]
    let deletableIds: Set<HouseworkImage.ID>
    let onDelete: (HouseworkImage) async throws -> Void

    @State var selectedId: HouseworkImage.ID
    /// 消す前の確認で確かめている画像
    @State var deletingImage: HouseworkImage?
    @State var imageError: HouseworkImageError?

    init(
        images: [HouseworkImage],
        initialId: HouseworkImage.ID,
        deletableIds: Set<HouseworkImage.ID>,
        onDelete: @escaping (HouseworkImage) async throws -> Void
    ) {
        self.images = images
        self.deletableIds = deletableIds
        self.onDelete = onDelete
        _selectedId = State(initialValue: initialId)
    }

    var body: some View {
        NavigationStack {
            HouseworkImageViewerView(
                images: images,
                selectedId: $selectedId,
                deletableIds: deletableIds,
                onTapClose: { dismiss() },
                onTapDelete: { image in deletingImage = image },
                page: { image in
                    HouseworkImageComponent(
                        source: .stored(image),
                        maxPixelSize: HouseworkImageProcessor.maxPixelSize,
                        contentMode: .fit
                    )
                }
            )
            .disabled(loadingState.isLoading)
        }
        .confirmationDialog(
            .localized("この画像を消しますか？"),
            isPresented: .init(get: { deletingImage != nil }, set: { if !$0 { deletingImage = nil } }),
            titleVisibility: .visible,
            presenting: deletingImage
        ) { image in
            Button(.localized("消す"), role: .destructive) {
                delete(image)
            }
            Button(.localized("キャンセル"), role: .cancel) {}
        } message: { _ in
            Text("同居人の画面からも見えなくなります。", bundle: #bundle)
        }
        .houseworkImageErrorAlert($imageError)
        .commonError(content: $commonErrorContent)
        .fullScreenLoadingIndicator(loadingState)
        .onChange(of: images) { _, newImages in
            didChangeImages(newImages)
        }
        .trackScreenView(.houseworkImageViewer)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkImageViewerScreen {

    func delete(_ image: HouseworkImage) {
        loadingState.task {
            do {
                try await onDelete(image)
            } catch let error as HouseworkImageError {
                imageError = error
            } catch {
                commonErrorContent = .init(error: error)
            }
        }
    }

    /// 消した画像の隣へ移る。画像が無くなったら閉じる
    func didChangeImages(_ newImages: [HouseworkImage]) {
        guard !newImages.contains(where: { $0.id == selectedId }) else { return }
        guard let nextImage = newImages.first else {
            dismiss()
            return
        }
        selectedId = nextImage.id
    }

}
