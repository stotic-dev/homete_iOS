//
//  SettingMenuItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeDomain
import SwiftUI

enum SettingMenuItem: Equatable, CaseIterable {

    case memberInvitation
    case taskTemplate
    case notificationPermission
    case premiumPlan
    case termsOfService
    case privacyPolicy
    case license
    #if DEBUG
    case debugMenu
    #endif

    /// 表示する項目を状態に応じて絞り込む
    /// - Parameters:
    ///   - isRegisteredGroup: グループに参加済みかどうか
    ///   - isAvailableInvitationLink: 招待リンクを利用できるビルドかどうか
    /// - Returns: 表示する項目
    static func displayItems(
        isRegisteredGroup: Bool,
        isAvailableInvitationLink: Bool
    ) -> [Self] {
        allCases.filter {
            switch $0 {
            case .taskTemplate:
                // テンプレート設定項目はグループ参加状態の時のみ表示する
                isRegisteredGroup

            case .memberInvitation:
                // 招待するグループが無い状態では意味を成さないため、参加済みの場合のみ表示する。
                // リンクを生成できないビルドでも導線ごと出さない
                isRegisteredGroup && isAvailableInvitationLink

            default:
                true
            }
        }
    }

    func title(plan: SubscriptionPlan) -> LocalizedStringKey {
        switch self {
        case .memberInvitation:
            "メンバー招待"

        case .taskTemplate:
            "家事テンプレート"

        case .notificationPermission:
            "通知設定"

        case .premiumPlan:
            if case .free = plan {
                "プレミアムプランに登録"
            } else {
                "ご登録中のプラン"
            }

        case .termsOfService:
            "利用規約"

        case .privacyPolicy:
            "プライバシーポリシー"

        case .license:
            "ライセンス"

        #if DEBUG
        case .debugMenu:
            "デバッグメニュー"
        #endif
        }
    }

    var iconName: String {
        switch self {
        case .memberInvitation:
            "person.badge.plus"

        case .taskTemplate:
            "house"

        case .notificationPermission:
            "bell.badge.fill"

        case .premiumPlan:
            "crown.fill"

        case .termsOfService:
            "doc.text"

        case .privacyPolicy:
            "hand.raised"

        case .license:
            "cube.box"

        #if DEBUG
        case .debugMenu:
            "ladybug"
        #endif
        }
    }

}
