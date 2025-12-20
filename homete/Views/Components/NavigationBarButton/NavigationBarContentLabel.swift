//
//  NavigationBarContentLabel.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct NavigationBarContentLabel {
    
    private let symbolName: String?
    private let assetIcon: ImageResource?
    
    var icon: Image {
        if let assetIcon {
            Image(assetIcon)
        }
        else {
            Image(systemName: symbolName ?? "")
        }
    }
}

extension NavigationBarContentLabel {
    
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
