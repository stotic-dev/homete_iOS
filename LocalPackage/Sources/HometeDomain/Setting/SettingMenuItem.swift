//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

public enum SettingMenuItem: Equatable, CaseIterable {

    case memberRegistration
    case taskTemplate
    case privacyPolicy
    case license

    public var title: LocalizedStringKey {
        switch self {
        case .memberRegistration:
            "メンバー追加"

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
        case .memberRegistration:
            "person.badge.plus"

        case .taskTemplate:
            "house"

        case .privacyPolicy:
            "hand.raised"

        case .license:
            "cube.box"
        }
    }

}
