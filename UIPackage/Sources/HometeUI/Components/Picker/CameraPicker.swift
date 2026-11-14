//
//  CameraPicker.swift
//  LocalPackage
//

import SwiftUI

#if os(iOS)
import UIKit

/// カメラで写真を1枚撮る（`UIImagePickerController`）
///
/// SwiftUIにはカメラで撮るためのViewが無いため、`.fullScreenCover`から表示できるこのラッパーを使う。
public struct CameraPicker: UIViewControllerRepresentable {

    let onPick: (Data) -> Void
    let onCancel: () -> Void

    /// - Parameters:
    ///   - onPick: 撮った写真（JPEG）。向きの情報はExifに残しているため、表示・縮小するときに反映する
    ///   - onCancel: 撮らずに閉じたとき
    public init(onPick: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    /// この端末でカメラを使えるか（シミュレータでは使えない）
    public static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        let onPick: (Data) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        public func imagePickerController(
            _: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                onCancel()
                return
            }
            Task {
                guard let data = await Self.encode(image) else {
                    onCancel()
                    return
                }
                onPick(data)
            }
        }

        public func imagePickerControllerDidCancel(_: UIImagePickerController) {
            onCancel()
        }

        /// 縮小・圧縮は受け取った側で行うため、ここでは画質をほとんど落とさずにJPEGにする
        /// - Note: 高画素の写真ではJPEGへの変換に時間がかかるため、メインスレッドの外で行う
        @concurrent
        static func encode(_ image: UIImage) async -> Data? {
            image.jpegData(compressionQuality: 0.9)
        }

    }

}
#else

/// iOS以外のプラットフォームではカメラを使わない
public struct CameraPicker: View {

    let onPick: (Data) -> Void
    let onCancel: () -> Void

    public init(onPick: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    public static var isAvailable: Bool {
        false
    }

    public var body: some View {
        EmptyView()
    }

}
#endif
