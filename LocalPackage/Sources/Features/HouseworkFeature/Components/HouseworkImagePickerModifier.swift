//
//  HouseworkImagePickerModifier.swift
//  LocalPackage
//

import HometeUI
import PhotosUI
import SwiftUI

extension View {

    /// 家事に添える画像を、フォトライブラリから選ぶ・カメラで撮る画面を出す
    /// - Parameters:
    ///   - source: 出す画面。閉じると`nil`に戻す
    ///   - maxSelectionCount: フォトライブラリから一度に選べる枚数（あと何枚添えられるか）
    ///   - onPick: 画像を選んだ・撮ったとき。受け取るのは1枚ずつ画像を読み込む処理で、
    ///             読み込みに時間がかかるため、呼び出し側が通信中の表示を出してから呼ぶ
    func houseworkImagePicker(
        source: Binding<HouseworkImagePickSource?>,
        maxSelectionCount: Int,
        onPick: @escaping (_ originals: [@Sendable () async -> Data?]) -> Void
    ) -> some View {
        modifier(HouseworkImagePickerModifier(source: source, maxSelectionCount: maxSelectionCount, onPick: onPick))
    }

}

private struct HouseworkImagePickerModifier: ViewModifier {

    @Binding var source: HouseworkImagePickSource?
    let maxSelectionCount: Int
    let onPick: (_ originals: [@Sendable () async -> Data?]) -> Void

    @State var selectedItems: [PhotosPickerItem] = []

    func body(content: Content) -> some View {
        content
            .photosPicker(
                isPresented: isPresented(.library),
                selection: $selectedItems,
                maxSelectionCount: max(maxSelectionCount, 1),
                matching: .images
            )
            .onChange(of: selectedItems) { _, items in
                pickedFromLibrary(items)
            }
            .fullScreenCoverOnIOS(isPresented: isPresented(.camera)) {
                CameraPicker { data in
                    source = nil
                    onPick([{ data }])
                } onCancel: {
                    source = nil
                }
                .ignoresSafeArea()
            }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkImagePickerModifier {

    func isPresented(_ target: HouseworkImagePickSource) -> Binding<Bool> {
        .init {
            source == target
        } set: { isPresented in
            if !isPresented {
                source = nil
            }
        }
    }

    func pickedFromLibrary(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        // 同じ写真を続けて選んでも変更が伝わるよう、受け取ったら選択を空に戻す
        selectedItems = []
        onPick(items.map { item in
            {
                do {
                    return try await item.loadTransferable(type: Data.self)
                } catch {
                    // iCloudから取り寄せられないなど、読み込めなかった写真は飛ばす
                    print("Failed loading picked photo: \(error)")
                    return nil
                }
            }
        })
    }

}
