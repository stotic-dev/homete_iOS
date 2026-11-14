//
//  SettingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import HometeModel
import HometeUI
import SwiftUI

/// 設定画面
/// - Note: メニューの操作・ログアウト・退会などの処理は`SettingMenuScreen`が受け持つ
public struct SettingView: View {

    let userName: String
    let plan: SubscriptionPlan
    /// 自分以外のグループのメンバー
    let otherMembers: [CohabitantMember]
    let menuGroups: [SettingMenuGroup]
    /// 運営からの未読の返信がある問い合わせの数
    let unreadInquiryCount: Int
    let isAnonymous: Bool
    let onTapMenuItem: (SettingMenuItem) -> Void
    let onTapAccountLink: () -> Void
    let onTapLogout: () -> Void
    let onTapAccountDeletion: () -> Void
    let onTapClose: () -> Void

    public init(
        userName: String,
        plan: SubscriptionPlan,
        otherMembers: [CohabitantMember],
        menuGroups: [SettingMenuGroup],
        unreadInquiryCount: Int,
        isAnonymous: Bool,
        onTapMenuItem: @escaping (SettingMenuItem) -> Void,
        onTapAccountLink: @escaping () -> Void,
        onTapLogout: @escaping () -> Void,
        onTapAccountDeletion: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.userName = userName
        self.plan = plan
        self.otherMembers = otherMembers
        self.menuGroups = menuGroups
        self.unreadInquiryCount = unreadInquiryCount
        self.isAnonymous = isAnonymous
        self.onTapMenuItem = onTapMenuItem
        self.onTapAccountLink = onTapAccountLink
        self.onTapLogout = onTapLogout
        self.onTapAccountDeletion = onTapAccountDeletion
        self.onTapClose = onTapClose
    }

    public var body: some View {
        // 表示項目が画面高さを超えるとナビゲーションバー領域にコンテンツが食い込むためScrollViewで包む
        ScrollView {
            VStack(spacing: .space32) {
                VStack(spacing: .space24) {
                    basicInfoSection(plan: plan)
                    GroupMemberListView(members: otherMembers)
                    Spacer()
                        .frame(height: .space16)
                    ForEach(menuGroups) { group in
                        SettingMenuSectionContent(
                            group: group,
                            plan: plan,
                            badgeCount: badgeCount(for:),
                            onTap: onTapMenuItem
                        )
                    }
                }
                VStack(spacing: .space24) {
                    // 匿名のアカウントはログアウトすると二度と入れなくなるため、代わりにApple連携を出す
                    if isAnonymous {
                        VStack(spacing: .space8) {
                            Button {
                                onTapAccountLink()
                            } label: {
                                Text("Appleでサインイン", bundle: #bundle)
                                    .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle()
                            Text("家事の記録を始めるには、Appleでのサインインが必要です", bundle: #bundle)
                                .font(with: .caption)
                                .foregroundStyle(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Button {
                            onTapLogout()
                        } label: {
                            Text("ログアウト", bundle: #bundle)
                                .frame(maxWidth: .infinity)
                        }
                        .subPrimaryButtonStyle()
                    }
                    Button {
                        onTapAccountDeletion()
                    } label: {
                        Text("退会", bundle: #bundle)
                            .frame(maxWidth: .infinity)
                    }
                    .destructiveButtonStyle()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space16)
        }
        .navigationTitle(.localized("設定"))
        // ホーム・家事ボード・分析のタブとそろえて、画面の地はミルク色にする
        .background(.backgroundScreen)
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trailingToolbarItem {
            leadingNavigationBarContent()
        }
    }

}

// MARK: - 表示内容

private extension SettingView {

    func badgeCount(for item: SettingMenuItem) -> Int {
        item == .inquiry ? unreadInquiryCount : 0
    }

}

private extension SettingView {

    func leadingNavigationBarContent() -> some View {
        NavigationBarButton(label: .close) {
            onTapClose()
        }
    }

    func basicInfoSection(plan: SubscriptionPlan) -> some View {
        VStack(spacing: .space8) {
            HStack(spacing: .zero) {
                Text("ユーザー名:", bundle: #bundle)
                    .font(with: .headLineS)
                Spacer()
                Text(userName)
                    .font(with: .body)
                    .lineLimit(1)
            }
            HStack(spacing: .zero) {
                Text("ご利用中のプラン:", bundle: #bundle)
                    .font(with: .headLineS)
                Spacer()
                VStack(alignment: .trailing, spacing: .space4) {
                    switch plan {
                    case .free:
                        Text("無料プラン", bundle: #bundle)
                            .font(with: .body)

                    case let .subscription(period, nextRenewalDate, willRenew):
                        Text(period.displayName)
                            .font(with: .body)
                            .lineLimit(1)
                        if let nextRenewalDate {
                            expirationText(date: nextRenewalDate, willRenew: willRenew)
                                .font(with: .caption)
                        }
                    }
                }
            }
        }
    }

    /// 解約済みの場合は更新されないため、日付の意味づけを切り替える
    @ViewBuilder
    func expirationText(date: Date, willRenew: Bool) -> some View {
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)

        if willRenew {
            Text("次回更新日: \(formattedDate)", bundle: #bundle)
        } else {
            Text("有効期限: \(formattedDate)", bundle: #bundle)
        }
    }

}

#if DEBUG
#Preview("SettingView_グループ未登録") {
    SettingView(
        userName: "Hoge",
        plan: .free,
        otherMembers: [],
        menuGroups: SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: false,
            isAvailableInvitationLink: true
        )),
        unreadInquiryCount: 0,
        isAnonymous: false,
        onTapMenuItem: { _ in },
        onTapAccountLink: {},
        onTapLogout: {},
        onTapAccountDeletion: {},
        onTapClose: {}
    )
}

#Preview("SettingView_匿名") {
    SettingView(
        userName: "Hoge",
        plan: .free,
        otherMembers: [],
        menuGroups: SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: false,
            isAvailableInvitationLink: true
        )),
        unreadInquiryCount: 0,
        isAnonymous: true,
        onTapMenuItem: { _ in },
        onTapAccountLink: {},
        onTapLogout: {},
        onTapAccountDeletion: {},
        onTapClose: {}
    )
}

#Preview("SettingView_グループ登録済み") {
    SettingView(
        userName: "Hoge",
        plan: .free,
        otherMembers: [
            .init(id: "user1", userName: "山田太郎"),
            .init(id: "user2", userName: "佐藤花子"),
        ],
        menuGroups: SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: true,
            isAvailableInvitationLink: true
        )),
        unreadInquiryCount: 0,
        isAnonymous: false,
        onTapMenuItem: { _ in },
        onTapAccountLink: {},
        onTapLogout: {},
        onTapAccountDeletion: {},
        onTapClose: {}
    )
}

#Preview("SettingView_プレミアム登録済み") {
    SettingView(
        userName: "Hoge",
        plan: .subscription(
            period: .monthly,
            // VRTで日付表示がブレないよう固定値にする（TZ差で日付がずれないよう正午JST）
            nextRenewalDate: .previewDate(year: 2026, month: 6, day: 17, hour: 12),
            willRenew: true
        ),
        otherMembers: [
            .init(id: "user1", userName: "山田太郎"),
            .init(id: "user2", userName: "佐藤花子"),
        ],
        menuGroups: SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: true,
            isAvailableInvitationLink: true
        )),
        unreadInquiryCount: 0,
        isAnonymous: false,
        onTapMenuItem: { _ in },
        onTapAccountLink: {},
        onTapLogout: {},
        onTapAccountDeletion: {},
        onTapClose: {}
    )
}

#Preview("SettingView_プレミアム登録済み_解約済み") {
    SettingView(
        userName: "Hoge",
        plan: .subscription(
            period: .yearly,
            // VRTで日付表示がブレないよう固定値にする（TZ差で日付がずれないよう正午JST）
            nextRenewalDate: .previewDate(year: 2026, month: 5, day: 28, hour: 12),
            willRenew: false
        ),
        otherMembers: [
            .init(id: "user1", userName: "山田太郎"),
            .init(id: "user2", userName: "佐藤花子"),
        ],
        menuGroups: SettingMenuGroup.make(from: SettingMenuItem.displayItems(
            isRegisteredGroup: true,
            isAvailableInvitationLink: true
        )),
        unreadInquiryCount: 0,
        isAnonymous: false,
        onTapMenuItem: { _ in },
        onTapAccountLink: {},
        onTapLogout: {},
        onTapAccountDeletion: {},
        onTapClose: {}
    )
}
#endif
