//
//  HouseworkTemplateItemDetailView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeModel
import HometeUI
import SwiftUI

/// テンプレートの家事の詳細画面
/// - Note: 編集モーダルの表示・削除後に閉じる操作は`HouseworkTemplateItemDetailScreen`が受け持つ
public struct HouseworkTemplateItemDetailView: View {

    let item: HouseworkTemplateItem
    let recurrence: HouseworkRecurrence
    let onTapEdit: () -> Void
    let onTapDelete: () -> Void

    public init(
        item: HouseworkTemplateItem,
        recurrence: HouseworkRecurrence,
        onTapEdit: @escaping () -> Void,
        onTapDelete: @escaping () -> Void
    ) {
        self.item = item
        self.recurrence = recurrence
        self.onTapEdit = onTapEdit
        self.onTapDelete = onTapDelete
    }

    public var body: some View {
        // メモが長くても読み切れるようにスクロールさせる
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                row(label: .localized("ポイント")) {
                    PointLabel(point: item.point)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                recurrenceContent()
                if let memo = item.memo, !memo.isEmpty {
                    row(label: .localized("メモ")) {
                        // テンプレートのメモのチェックは、作られた家事の側で付ける
                        HouseworkMemoContent(memo: memo, isEditable: false, onToggle: { _ in })
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // テンプレートからの遷移で地の色が変わらないよう、テンプレートと同じミルク色にする
        .background(.backgroundScreen)
        .navigationTitle(item.title)
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            editingButton()
        }
    }

}

// MARK: - UI定義

private extension HouseworkTemplateItemDetailView {

    func row(label: LocalizedStringResource, @ViewBuilder valueContent: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(label)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            valueContent()
        }
    }

    @ViewBuilder
    func recurrenceContent() -> some View {
        switch recurrence {
        case let .weekly(days) where days.count == DayOfWeek.allCases.count:
            row(label: .localized("くり返し")) {
                Text("毎日", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }

        case let .weekly(days):
            row(label: .localized("くり返す曜日")) {
                HStack(spacing: .space8) {
                    ForEach(DayOfWeek.displayOrdered.filter { days.contains($0) }) { day in
                        WeekdayLabel(
                            weekday: day,
                            isSelected: true
                        )
                        .frame(width: 40)
                    }
                    Spacer()
                }
            }

        case let .monthly(rule):
            row(label: .localized("くり返し")) {
                Text(rule.label)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
        }
    }

    func editingButton() -> some View {
        HStack(spacing: .space8) {
            Button {
                onTapEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.textPrimary)
            }
            NavigationBarButton(label: .delete) {
                onTapDelete()
            }
        }
    }

}

#Preview("HouseworkTemplateItemDetailView_閲覧モード") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "洗濯",
                point: 10,
                updatedAt: .distantPast
            ),
            recurrence: .weekly([.monday, .wednesday]),
            onTapEdit: {},
            onTapDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_メモあり") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "買い出し",
                point: 10,
                updatedAt: .distantPast,
                memo: .init(
                    text: "駅前のスーパーで",
                    checklist: [
                        .init(id: "1", title: "牛乳", isChecked: false),
                        .init(id: "2", title: "卵", isChecked: false),
                    ]
                )
            ),
            recurrence: .weekly([.saturday]),
            onTapEdit: {},
            onTapDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_毎月") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "家賃の振込",
                point: 5,
                updatedAt: .distantPast
            ),
            recurrence: .monthly(.dayOfMonth(25)),
            onTapEdit: {},
            onTapDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_毎日") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "食器洗い",
                point: 5,
                updatedAt: .distantPast
            ),
            recurrence: .weekly(Set(DayOfWeek.allCases)),
            onTapEdit: {},
            onTapDelete: {}
        )
    }
}
