//
//  HouseworkTemplateView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事テンプレートの画面
/// - Note: 編集中の内容の更新・保存・シートと画面遷移は`HouseworkTemplateScreen`が受け持つ。
///         `NavigationStack`の中に置かれる前提でツールバーの項目を並べる
public struct HouseworkTemplateView: View {

    @State var bannerDismissedInSession = false

    @AppStorage(key: .collapsedHouseworkTemplateDays) var collapsedDays = CollapsedHouseworkTemplateDays()

    let content: Content
    /// 編集中のテンプレート
    let draft: HouseworkTemplateDraft
    /// 同時に編集しているメンバー
    let activeEditors: [TemplateActiveEditor]
    let isShowAd: Bool
    let actions: Actions

    public init(
        content: Content,
        draft: HouseworkTemplateDraft,
        activeEditors: [TemplateActiveEditor],
        isShowAd: Bool,
        actions: Actions
    ) {
        self.content = content
        self.draft = draft
        self.activeEditors = activeEditors
        self.isShowAd = isShowAd
        self.actions = actions
    }

    public var body: some View {
        ZStack {
            switch content {
            case let .loadFailed(error):
                LoadErrorView(error: error) {
                    actions.onRetry()
                }

            case let .editing(hasUnsavedChanges):
                HouseworkTemplateListContent(
                    collapsedDays: $collapsedDays,
                    draft: draft,
                    hasUnsavedChanges: hasUnsavedChanges,
                    onTapItem: actions.onTapItem,
                    onTapEdit: actions.onTapEdit,
                    onTapDelete: actions.onTapDelete,
                    onDropItem: actions.onDropItem,
                    onTapAdd: actions.onTapAdd,
                    onTapReset: actions.onTapReset,
                    onTapSave: actions.onTapSave
                )

            case .empty:
                HouseworkTemplateEmptyView {
                    actions.onTapCreateTemplate()
                }
            }
        }
        // 白い曜日のカードが地に溶けないよう、ほかのタブと同じミルク色を地に敷く
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundScreen)
        .navigationTitle(.localized("家事テンプレート"))
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .leadingToolbarItem {
            leadingNavigationItem()
        }
        .safeAreaInset(edge: .top) {
            HouseworkTemplateEditorsLabel(
                bannerDismissedInSession: $bannerDismissedInSession,
                activeEditors: activeEditors
            )
            .padding(.horizontal, .space16)
        }
        .bottomAdBanner(.houseworkTemplateBottom, isPresented: isShowAd, onTapPromotionLink: actions.onTapRemoveAdsLink)
        .animation(.default, value: collapsedDays)
    }

}

public extension HouseworkTemplateView {

    /// 画面に出す内容
    enum Content: Equatable {

        /// テンプレートの取得・購読に失敗している
        case loadFailed(DomainError)
        /// テンプレートを編集している
        /// - Parameter hasUnsavedChanges: 保存していない変更があるか
        case editing(hasUnsavedChanges: Bool)
        /// テンプレートをまだ作っていない
        case empty

    }

    /// 画面の操作
    struct Actions {

        public let onRetry: () -> Void
        public let onTapItem: (HouseworkTemplateItem) -> Void
        public let onTapEdit: (HouseworkTemplateItem) -> Void
        /// - Parameter day: 毎週の家事を、この曜日からだけ外す。`nil`なら家事ごと消す
        public let onTapDelete: (HouseworkTemplateItem.ItemId, _ day: DayOfWeek?) -> Void
        public let onDropItem: (HouseworkTemplateItem.ItemId, _ destination: DayOfWeek) -> Void
        public let onTapAdd: () -> Void
        public let onTapReset: () -> Void
        public let onTapSave: () -> Void
        public let onTapCreateTemplate: () -> Void
        public let onTapClose: () -> Void
        public let onTapRemoveAdsLink: () -> Void

        public init(
            onRetry: @escaping () -> Void = {},
            onTapItem: @escaping (HouseworkTemplateItem) -> Void = { _ in },
            onTapEdit: @escaping (HouseworkTemplateItem) -> Void = { _ in },
            onTapDelete: @escaping (HouseworkTemplateItem.ItemId, _ day: DayOfWeek?) -> Void = { _, _ in },
            onDropItem: @escaping (HouseworkTemplateItem.ItemId, _ destination: DayOfWeek) -> Void = { _, _ in },
            onTapAdd: @escaping () -> Void = {},
            onTapReset: @escaping () -> Void = {},
            onTapSave: @escaping () -> Void = {},
            onTapCreateTemplate: @escaping () -> Void = {},
            onTapClose: @escaping () -> Void = {},
            onTapRemoveAdsLink: @escaping () -> Void = {}
        ) {
            self.onRetry = onRetry
            self.onTapItem = onTapItem
            self.onTapEdit = onTapEdit
            self.onTapDelete = onTapDelete
            self.onDropItem = onDropItem
            self.onTapAdd = onTapAdd
            self.onTapReset = onTapReset
            self.onTapSave = onTapSave
            self.onTapCreateTemplate = onTapCreateTemplate
            self.onTapClose = onTapClose
            self.onTapRemoveAdsLink = onTapRemoveAdsLink
        }

    }

}

// MARK: - ナビゲーションバー

private extension HouseworkTemplateView {

    func leadingNavigationItem() -> some View {
        Button {
            actions.onTapClose()
        } label: {
            Image(systemName: "xmark")
        }
        .foregroundStyle(.textPrimary)
    }

}

// MARK: - Preview

#if DEBUG
#Preview("HouseworkTemplateView_閲覧モード") {
    let templateData: [DayOfWeek: [HouseworkTemplateItem]] = [
        .monday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
        .tuesday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
            .init(
                id: .init(id: "2"),
                title: "hoge2",
                point: 15,
                updatedAt: .now
            ),
        ],
        .wednesday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
        .thursday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
            .init(
                id: .init(id: "3"),
                title: "hoge3",
                point: 90,
                updatedAt: .now
            ),
        ],
        .friday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
        .saturday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
        .sunday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
    ]
    let monthlyItems: [HouseworkTemplateMonthlyItem] = [
        .init(
            item: .init(id: .init(id: "4"), title: "家賃の振込", point: 5, updatedAt: .now),
            rule: .dayOfMonth(25)
        ),
        .init(
            item: .init(id: .init(id: "5"), title: "月末の水回り掃除", point: 3, updatedAt: .now),
            rule: .dayOfMonth(31)
        ),
    ]
    HouseworkTemplateView(
        content: .editing(hasUnsavedChanges: false),
        draft: .init(days: templateData, monthlyItems: monthlyItems),
        activeEditors: [],
        isShowAd: true,
        actions: .init()
    )
    .apply(theme: .init())
}

#Preview("HouseworkTemplateView_アクティブユーザー有り") {
    let templateData: [DayOfWeek: [HouseworkTemplateItem]] = [
        .monday: [
            .init(
                id: .init(id: "1"),
                title: "hoge",
                point: 10,
                updatedAt: .now
            ),
        ],
    ]
    HouseworkTemplateView(
        content: .editing(hasUnsavedChanges: HouseworkTemplateDraft(days: templateData)
            .hasUnsavedChanges(comparedTo: .init())),
        draft: .init(),
        activeEditors: [
            .init(id: "1", userName: "Aさん"),
            .init(id: "2", userName: "Bさん"),
        ],
        isShowAd: true,
        actions: .init()
    )
    .apply(theme: .init())
}

#Preview("HouseworkTemplateView_読み込みエラー") {
    HouseworkTemplateView(
        content: .loadFailed(.noNetwork),
        draft: .init(),
        activeEditors: [],
        isShowAd: true,
        actions: .init()
    )
    .apply(theme: .init())
}
#endif
