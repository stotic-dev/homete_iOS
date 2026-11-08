//
//  HouseworkImageComponent.swift
//  LocalPackage
//

import HometeDomain
import HouseworkFeatureUI
import SwiftUI

/// 家事に添えた画像を読み込んで1枚表示する
struct HouseworkImageComponent: View {

    /// 表示する画像の取り出し元
    enum Source: Equatable {

        /// 家事に添えてある画像（保存先から取得する）
        case stored(HouseworkImage)
        /// まだ上げていない、入力中の家事の画像
        case pending(HouseworkImageUpload)

        var id: String {
            switch self {
            case let .stored(image):
                image.id

            case let .pending(upload):
                upload.id
            }
        }

    }

    @Environment(\.appDependencies.houseworkImageClient) var houseworkImageClient

    let source: Source
    /// 表示する大きさに合わせて縮小して読み込む。元の大きさのまま展開するとメモリを大きく使うため
    let maxPixelSize: Int
    let contentMode: ContentMode

    @State var phase = HouseworkImagePhase.loading

    var body: some View {
        HouseworkImageContent(phase: phase, contentMode: contentMode)
            .task(id: source.id) {
                await load()
            }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkImageComponent {

    func load() async {
        do {
            let data = switch source {
            case let .stored(image):
                try await houseworkImageClient.fetch(image.storagePath)

            case let .pending(upload):
                upload.data
            }
            let image = await HouseworkImageProcessor.loadImage(from: data, maxPixelSize: maxPixelSize)
            phase = image.map { .loaded($0) } ?? .failed
        } catch is CancellationError {
            // 一覧・ページから外れて読み込みを止めただけなので、失敗の表示にしない
            return
        } catch {
            print("Failed loading housework image: \(error)")
            phase = .failed
        }
    }

}
