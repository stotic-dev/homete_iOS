//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

enum SettingMenuItem: Equatable, CaseIterable {

    case taskTemplate
    case privacyPolicy
    case license

    static func displayItems(_ isRegisteredGroup: Bool) -> [Self] {
        allCases.filter {
            if $0 == .taskTemplate {
                // テンプレート設定項目はグループ参加状態の時のみ表示する
                isRegisteredGroup
            } else {
                true
            }
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .taskTemplate:
            "家事テンプレート"

        case .privacyPolicy:
            "プライバシーポリシー"

        case .license:
            "ライセンス"
        }
    }

    var iconName: String {
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
