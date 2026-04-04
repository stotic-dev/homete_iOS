//
//  DesignSystem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/05.
//

import SwiftUI

public enum DesignSystem {}

// MARK: Spaceの定義

public extension CGFloat {

    static let space4: CGFloat = 4
    static let space8: CGFloat = 8
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48
    static let space56: CGFloat = 56
    static let space64: CGFloat = 64
}

// MARK: Fontの定義

public extension DesignSystem {

    enum Font {

        case headLineL
        case headLineM
        case headLineS
        case body
        case caption

        var value: SwiftUI.Font {

            switch self {

            case .headLineL: .title.weight(.heavy)
            case .headLineM: .title2.weight(.heavy)
            case .headLineS: .headline
            case .body: .body
            case .caption: .caption
            }
        }
    }
}

public extension View {

    func font(with font: DesignSystem.Font) -> some View {

        return self.font(font.value)
    }
}

// MARK: CornerRadiusの定義

public extension DesignSystem {

    enum Corner: CGFloat {

        case radius8 = 8
        case radius16 = 16
    }
}

public extension View {

    func cornerRadius(_ radius: DesignSystem.Corner) -> some View {
        self.clipShape(RoundedRectangle(radius: radius))
    }
}

public extension RoundedRectangle {

    init(radius: DesignSystem.Corner) {

        self.init(cornerRadius: radius.rawValue)
    }
}
