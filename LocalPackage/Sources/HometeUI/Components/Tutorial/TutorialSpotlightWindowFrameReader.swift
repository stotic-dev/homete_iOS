//
//  TutorialSpotlightWindowFrameReader.swift
//  LocalPackage
//

#if os(iOS)
import SwiftUI
import UIKit

/// 置かれた位置を、ウィンドウの座標で測って伝える
///
/// ナビゲーションバーの項目は、表示される前（タブが選ばれる前など）に作られることがあり、
/// そのときに測った位置はウィンドウの上の位置にならない。ウィンドウに載ったときにも測り直す。
struct TutorialSpotlightWindowFrameReader: UIViewRepresentable {

    /// 変わったら測り直す値。SwiftUIの上での位置を渡し、スクロールなどで動いたことを拾う
    let trigger: CGRect?
    let onChange: (CGRect) -> Void

    func makeUIView(context _: Context) -> ReaderView {
        let view = ReaderView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ReaderView, context _: Context) {
        uiView.onChange = onChange
        uiView.measureAfterLayout()
    }

    final class ReaderView: UIView {

        var onChange: ((CGRect) -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            measure()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            measureAfterLayout()
        }

        /// SwiftUIの更新がUIKitの配置に反映されてから測る
        func measureAfterLayout() {
            Task { @MainActor [weak self] in
                self?.measure()
            }
        }

        private func measure() {
            guard let window else { return }

            onChange?(convert(bounds, to: window))
        }

    }

}
#endif
