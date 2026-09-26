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
    @State var safeAreaInsets = EdgeInsets()

    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            content
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
                    safeAreaInsets = insets
                }
        }
        .presentationDetents(detents)
    }

}

private extension ContentFittingSheetScrollView {

    /// 中身の高さを測るまでは、いつものハーフモーダルの高さで出しておく
    var detents: Set<PresentationDetent> {
        guard let contentHeight else { return [.medium] }

        return [.height(contentHeight + safeAreaInsets.top + safeAreaInsets.bottom)]
    }

}
