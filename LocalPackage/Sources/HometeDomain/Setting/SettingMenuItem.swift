//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

public enum SettingMenuItem: Equatable, CaseIterable {

    case taskTemplate
    case privacyPolicy
    case license

    #if canImport(SwiftUI)
    public var title: LocalizedStringKey {

        switch self {
        case .taskTemplate:
            return "家事テンプレート"

        case .privacyPolicy:
            return "プライバシーポリシー"

        case .license:
            return "ライセンス"
        }
    }
    #endif

    public var iconName: String {

        switch self {
        case .taskTemplate:
            return "house"

        case .privacyPolicy:
            return "hand.raised"

        case .license:
            return "cube.box"
        }
    }
}
