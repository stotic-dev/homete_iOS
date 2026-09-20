//
//  ShareSheet.swift
//  LocalPackage
//

import SwiftUI

#if os(iOS)
import UIKit

/// テキストとURLをOSの共有シート（`UIActivityViewController`）で共有する
///
/// 共有するURLは非同期に発行されるため、`ShareLink`ではなく
/// `.sheet`から表示できるこのラッパーを使う。
public struct ShareSheet: UIViewControllerRepresentable {

    let text: String
    let url: URL
    let onComplete: ((Bool) -> Void)?

    /// - Parameters:
    ///   - text: 共有するテキスト
    ///   - url: 共有するURL
    ///   - onComplete: 共有シートが閉じたときに呼ばれる。共有先のアプリで共有まで完了した場合は`true`、
    ///                 キャンセルした場合は`false`
    public init(text: String, url: URL, onComplete: ((Bool) -> Void)? = nil) {
        self.text = text
        self.url = url
        self.onComplete = onComplete
    }

    public func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return controller
    }

    public func updateUIViewController(_: UIActivityViewController, context _: Context) {}

}
#else

/// iOS以外のプラットフォームでは共有シートを表示しない
public struct ShareSheet: View {

    let text: String
    let url: URL
    let onComplete: ((Bool) -> Void)?

    public init(text: String, url: URL, onComplete: ((Bool) -> Void)? = nil) {
        self.text = text
        self.url = url
        self.onComplete = onComplete
    }

    public var body: some View {
        EmptyView()
    }

}
#endif
