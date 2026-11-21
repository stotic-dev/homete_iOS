//
//  NavigationBarSpacer.swift
//  UIPackage
//

import SwiftUI

#if os(iOS)
/// ナビゲーションバーの項目の間に挟む`ToolbarSpacer`。iOS 26未満では何も出さない
///
/// iOS 26では1つの`ToolbarItem`にボタンをまとめるとガラスの背景がひとつながりになるため、項目を分けてこれを挟む。
///
/// - Note: `toolbar`の中に`if #available { ToolbarSpacer(...) }`を直に書かず、これを使う。
///         直に書くと、そのViewの型にSwiftUIの`buildLimitedAvailability`の不透明型が含まれる。
///         `public`なViewやModifierの中でそうすると、Release構成ではモジュールをまたぐ最適化で
///         呼び出し側のモジュールがこの型のシンボルを直接参照するが、SwiftUIはこのシンボルを公開していないため
///         Archiveのリンクに失敗する。型に包むことで、呼び出し側から見える型に出さないようにしている
public struct NavigationBarSpacer: ToolbarContent {

    public enum Sizing {

        /// 決まった幅の間隔
        case fixed
        /// 空いている幅いっぱいに広がる間隔
        case flexible

    }

    private let sizing: Sizing
    private let placement: ToolbarItemPlacement

    public init(_ sizing: Sizing = .fixed, placement: ToolbarItemPlacement = .automatic) {
        self.sizing = sizing
        self.placement = placement
    }

    public var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarSpacer(sizing.spacerSizing, placement: placement)
        }
    }

}

@available(iOS 26.0, *)
private extension NavigationBarSpacer.Sizing {

    var spacerSizing: SpacerSizing {
        switch self {
        case .fixed:
            .fixed

        case .flexible:
            .flexible
        }
    }

}
#endif
