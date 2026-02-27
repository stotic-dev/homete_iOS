//
//  NavigationBarContentLabel.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

#if canImport(UIKit)
import SwiftUI

public struct NavigationBarContentLabel: Sendable {

    private let symbolName: String?
    private let assetIcon: ImageResource?

    public var icon: Image {
        if let assetIcon {
            Image(assetIcon)
        }
        else {
            Image(systemName: symbolName ?? "")
        }
    }
}

public extension NavigationBarContentLabel {

    static let settings = NavigationBarContentLabel(
        symbolName: "gearshape",
        assetIcon: nil
    )
    static let close = NavigationBarContentLabel(
        symbolName: "xmark",
        assetIcon: nil
    )
    static let delete = NavigationBarContentLabel(
        symbolName: "trash",
        assetIcon: nil
    )
}
#endif
