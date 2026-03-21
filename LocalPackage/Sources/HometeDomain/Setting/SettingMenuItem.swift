//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

public enum SettingMenuItem: Equatable, CaseIterable {

    case taskTemplate
    case privacyPolicy
    case license

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
