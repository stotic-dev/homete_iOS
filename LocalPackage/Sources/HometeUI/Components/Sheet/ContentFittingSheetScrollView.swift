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
    @State var safeAreaHeight: CGFloat = .zero

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
            // ナビゲーションバーと下端のセーフエリアの分を足さないと、シートが中身より低くなって見切れる。
            // セーフエリアの値は無視しているViewだけが受け取れる（無視していないViewでは0になる）ため、
            // ここで無視して測る。キーボードの分まで足すとキーボードを出すたびにシートが伸びてしまうので、
            // .keyboardは無視せず.containerだけを無視する
            Color.clear
                .ignoresSafeArea(.container)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                } action: { height in
                    // 最初の計測ではまだ0（ナビゲーションバーが決まる前）なので、一番大きい値を使う。
                    // セーフエリアはシートの位置でも変わる（キーボードで押し上げられ上端がステータスバーに
                    // かかると上側が増える）が、縮む方向にも追従すると高さとセーフエリアが互いに影響し合って
                    // 永遠に揺れ続けるため、伸びる方向にだけ追従する
                    safeAreaHeight = max(safeAreaHeight, height)
                }
        }
        .presentationDetents(detents)
    }

}

private extension ContentFittingSheetScrollView {

    /// 中身の高さを測るまでは、いつものハーフモーダルの高さで出しておく
    var detents: Set<PresentationDetent> {
        guard let contentHeight else { return [.medium] }

        return [.height(contentHeight + safeAreaHeight)]
    }

}
