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
    case frequentHousework
    case notificationPermission
    case premiumPlan
    case inquiry
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
            case .taskTemplate, .frequentHousework:
                // テンプレート・いつもの家事はグループで共有するため、グループ参加状態の時のみ表示する
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

    /// 設定画面でまとめて表示する区分
    var section: SettingMenuSection {
        switch self {
        case .memberInvitation:
            .group

        case .taskTemplate, .frequentHousework:
            .housework

        case .notificationPermission, .premiumPlan:
            .app

        case .inquiry:
            .support

        case .termsOfService, .privacyPolicy, .license:
            .about

        #if DEBUG
        case .debugMenu:
            .developer
        #endif
        }
    }

    func title(plan: SubscriptionPlan) -> LocalizedStringResource {
        switch self {
        case .memberInvitation:
            .localized("メンバー招待")

        case .taskTemplate:
            .localized("家事テンプレート")

        case .frequentHousework:
            .localized("いつもの家事")

        case .notificationPermission:
            .localized("通知設定")

        case .premiumPlan:
            premiumPlanTitle(plan: plan)

        case .inquiry:
            .localized("お問い合わせ")

        case .termsOfService:
            .localized("利用規約")

        case .privacyPolicy:
            .localized("プライバシーポリシー")

        case .license:
            .localized("ライセンス")

        #if DEBUG
        case .debugMenu:
            .localized("デバッグメニュー")
        #endif
        }
    }

    var iconName: String {
        switch self {
        case .memberInvitation:
            "person.badge.plus"

        case .taskTemplate:
            "house"

        case .frequentHousework:
            "star.square.on.square"

        case .notificationPermission:
            "bell.badge.fill"

        case .premiumPlan:
            "crown.fill"

        case .inquiry:
            "envelope"

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

private extension SettingMenuItem {

    func premiumPlanTitle(plan: SubscriptionPlan) -> LocalizedStringResource {
        if case .free = plan {
            .localized("プレミアムプランに登録")
        } else {
            .localized("ご登録中のプラン")
        }
    }

}
