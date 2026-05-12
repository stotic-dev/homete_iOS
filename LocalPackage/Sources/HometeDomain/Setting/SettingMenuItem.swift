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
            "家事テンプレート"

        case .privacyPolicy:
            "プライバシーポリシー"

        case .license:
            "ライセンス"
        }
    }

    public var iconName: String {
        switch self {
        case .taskTemplate:
            "house"

        case .privacyPolicy:
            "hand.raised"

        case .license:
            "cube.box"
        }
    }

}
