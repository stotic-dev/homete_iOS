//
//  NavigationBarMenuButton.swift
//  LocalPackage
//

import SwiftUI

/// タップするとメニューを出すナビゲーションバーのボタン
///
/// 見た目は`NavigationBarButton`と同じにして、並んだときにボタンの種類で大きさや色が変わらないようにする。
public struct NavigationBarMenuButton<Content: View>: View {

    public let label: NavigationBarContentLabel
    public let content: () -> Content

    public init(label: NavigationBarContentLabel, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    public var body: some View {
        Menu {
            content()
        } label: {
            label.icon
                .padding(.space8)
                .foregroundStyle(.onSurface)
        }
        .accessibilityLabel(label.accessibilityLabel)
    }

}
