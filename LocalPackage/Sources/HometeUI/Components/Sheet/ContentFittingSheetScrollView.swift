//
//  ContentFittingSheetScrollView.swift
//  LocalPackage
//

import SwiftUI

/// 中身の高さに合わせてシートの高さを決めるScrollView
///
/// シートの中（`NavigationStack`の中でもよい）に置くと、中身の高さにナビゲーションバーと下端のセーフエリアを
/// 足した高さをシートのデテントにする。中身の高さが変わればシートの高さも追従し、画面に収まらないときは
/// シートが最大の高さになって中身をスクロールできる。
public struct ContentFittingSheetScrollView<Content: View>: View {

    @State var contentHeight: CGFloat?
    @State var initialSafeAreaInsets: EdgeInsets?

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            content
                // 提案された高さをそのまま使うと、シートの高さが中身の高さに跳ね返って永遠に揺れ続けるため、
                // 中身は固有の高さで測る（キーボードの開閉でシートの高さが変わっても計測値を動かさない）
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background {
            // キーボードの分のセーフエリアまで足すと、キーボードを出すたびにシートが伸びてしまうため除く
            Color.clear
                .ignoresSafeArea(.keyboard)
                .onGeometryChange(for: EdgeInsets.self) { proxy in
                    proxy.safeAreaInsets
                } action: { insets in
                    // セーフエリアはシートの位置で変わる（キーボードで押し上げられ上端がステータスバーに
                    // かかると上側が増える）。それを高さの指定に反映すると、高さとセーフエリアが互いに
                    // 影響し合って永遠に揺れ続けるため、最初に測った値だけを使う
                    guard initialSafeAreaInsets == nil else { return }

                    initialSafeAreaInsets = insets
                }
        }
        .presentationDetents(detents)
    }

}

private extension ContentFittingSheetScrollView {

    /// 中身の高さを測るまでは、いつものハーフモーダルの高さで出しておく
    var detents: Set<PresentationDetent> {
        guard let contentHeight, let initialSafeAreaInsets else { return [.medium] }

        return [.height(contentHeight + initialSafeAreaInsets.top + initialSafeAreaInsets.bottom)]
    }

}
