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

    public init(text: String, url: URL) {
        self.text = text
        self.url = url
    }

    public func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text, url], applicationActivities: nil)
    }

    public func updateUIViewController(_: UIActivityViewController, context _: Context) {}

}
#else

/// iOS以外のプラットフォームでは共有シートを表示しない
public struct ShareSheet: View {

    let text: String
    let url: URL

    public init(text: String, url: URL) {
        self.text = text
        self.url = url
    }

    public var body: some View {
        EmptyView()
    }

}
#endif
