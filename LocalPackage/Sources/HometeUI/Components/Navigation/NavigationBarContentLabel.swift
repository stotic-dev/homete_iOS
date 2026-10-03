//
//  NavigationBarContentLabel.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

public struct NavigationBarContentLabel: Sendable {

    private let symbolName: String?
    private let assetIcon: ImageResource?
    /// VoiceOverで読み上げる名前
    ///
    /// ナビゲーションバーのボタンはアイコンだけで文字を持たないため、付けないとSF Symbolの名前が
    /// そのまま英語で読み上げられる。
    public let accessibilityLabel: String

    public var icon: Image {
        if let assetIcon {
            Image(assetIcon)
        } else {
            Image(systemName: symbolName ?? "")
        }
    }

}

public extension NavigationBarContentLabel {

    static let settings = NavigationBarContentLabel(
        symbolName: "gearshape",
        assetIcon: nil,
        accessibilityLabel: "設定"
    )
    static let close = NavigationBarContentLabel(
        symbolName: "xmark",
        assetIcon: nil,
        accessibilityLabel: "閉じる"
    )
    static let delete = NavigationBarContentLabel(
        symbolName: "trash",
        assetIcon: nil,
        accessibilityLabel: "削除"
    )
    static let houseworkTemplate = NavigationBarContentLabel(
        symbolName: "list.bullet.rectangle",
        assetIcon: nil,
        accessibilityLabel: "家事テンプレート"
    )
    /// メニューを開いて、画面で行える残りの操作を出すボタン
    static let more = NavigationBarContentLabel(
        symbolName: "ellipsis",
        assetIcon: nil,
        accessibilityLabel: "その他の操作"
    )

    /// 画面ごとの操作に合わせたアイコンを、ナビゲーションバーのボタンと同じ見た目で使う
    ///
    /// 定数として並べるのは複数の画面で共有するアイコンだけにして、1つの画面の操作に紐づくものは
    /// 呼び出し側から渡す。
    static func symbol(_ symbolName: String, accessibilityLabel: String) -> Self {
        .init(symbolName: symbolName, assetIcon: nil, accessibilityLabel: accessibilityLabel)
    }

}
