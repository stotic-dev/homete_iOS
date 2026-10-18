//
//  HouseworkTemplateTutorialView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 家事テンプレート画面のチュートリアルで、本番の画面の上に重ねて表示する画面
///
/// テンプレートの有無で本番の画面に出るUIが変わるため、本番の状態に左右されずに説明できるよう、
/// 本番と同じ`HouseworkTemplateEmptyView`・`HouseworkTemplateListContent`にサンプルの値を渡して表示する。
/// スポットライトで説明するUIを切り抜き、ステップごとの説明のカードを重ねる。
/// 操作はスポットライト側で受け止めるため、サンプルの画面のタップには何も割り当てない。
struct HouseworkTemplateTutorialView: View {

    let step: HouseworkTemplateTutorialStep
    /// 今回出すステップ。テンプレートを作成済みなら作成のステップを除く
    var steps = HouseworkTemplateTutorialStep.allCases
    let onTapNext: () -> Void
    let onTapBack: () -> Void
    let onTapClose: () -> Void

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundScreen)
                .navigationTitle(.localized("家事テンプレート"))
                .inlineNavigationBarTitleDisplayMode()
                .leadingToolbarItem {
                    Image(systemName: "xmark")
                        .foregroundStyle(.textPrimary)
                }
                .tutorialSpotlightNavigationBarTarget(.houseworkTemplateNavigationBar)
        }
        .tutorialSpotlight(isPresented: true, targets: spotlightTargets) {
            HouseworkTemplateTutorialCard(
                step: step,
                steps: steps,
                onTapNext: onTapNext,
                onTapBack: onTapBack,
                onTapClose: onTapClose
            )
        }
    }

}

private extension HouseworkTemplateTutorialView {

    /// ステップごとに切り抜くUI
    var spotlightTargets: [TutorialSpotlightID] {
        switch step {
        case .create:
            [.houseworkTemplateCreateButton]

        case .addItem:
            [.houseworkTemplateAddButton]

        case .autoPlacement:
            // 「毎月」のセクションは画面の下にあり、説明のカードを置く空きが無くなるため切り抜かない
            [.houseworkTemplateFirstDaySection]

        case .save:
            [.houseworkTemplateNavigationBar]
        }
    }

    @ViewBuilder
    var content: some View {
        switch step {
        case .create:
            HouseworkTemplateEmptyView(onCreate: {})

        case .addItem, .autoPlacement, .save:
            HouseworkTemplateListContent(
                collapsedDays: .constant(Self.collapsedDays),
                draft: Self.sampleDraft,
                // 保存ボタンを押せる見た目で説明する
                hasUnsavedChanges: step == .save,
                onTapItem: { _ in },
                onTapEdit: { _ in },
                onTapDelete: { _, _ in },
                onDropItem: { _, _ in },
                onTapAdd: {},
                onTapReset: {},
                onTapSave: {}
            )
        }
    }

    /// 先頭の曜日だけを開き、毎月のセクションまで1画面に収める
    static var collapsedDays: CollapsedHouseworkTemplateDays {
        .init(days: Set(DayOfWeek.displayOrdered.dropFirst()))
    }

    static var sampleDraft: HouseworkTemplateDraft {
        let item = { (id: String, title: LocalizedStringResource, point: Int) in
            HouseworkTemplateItem(id: .init(id: id), title: title.resolved(), point: point, updatedAt: .distantPast)
        }
        return .init(
            days: [
                .monday: [
                    item("1", .localized("ゴミ出し", comment: "チュートリアルの見本で出す家事の名前"), 10),
                    item("2", .localized("掃除機がけ", comment: "チュートリアルの見本で出す家事の名前"), 20),
                ],
                .thursday: [
                    item("3", .localized("ゴミ出し", comment: "チュートリアルの見本で出す家事の名前"), 10),
                ],
                .saturday: [
                    item("4", .localized("お風呂掃除", comment: "チュートリアルの見本で出す家事の名前"), 30),
                ],
            ],
            monthlyItems: [
                .init(
                    item: item("5", .localized("シーツの洗濯", comment: "チュートリアルの見本で出す家事の名前"), 20),
                    rule: .dayOfMonth(1)
                ),
            ]
        )
    }

}

#if DEBUG
// - Note: スポットライトは、切り抜くUIが位置を伝えてから描き直されるため、少し待ってから撮る
#Preview("HouseworkTemplateTutorialView_作成") {
    HouseworkTemplateTutorialView(step: .create, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .apply(theme: .init())
    #if canImport(Prefire)
        .snapshot(delay: 0.5)
    #endif
}

#Preview("HouseworkTemplateTutorialView_追加") {
    HouseworkTemplateTutorialView(step: .addItem, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .apply(theme: .init())
    #if canImport(Prefire)
        .snapshot(delay: 0.5)
    #endif
}

#Preview("HouseworkTemplateTutorialView_作成済みで追加") {
    HouseworkTemplateTutorialView(
        step: .addItem,
        steps: [.addItem, .autoPlacement, .save],
        onTapNext: {},
        onTapBack: {},
        onTapClose: {}
    )
    .apply(theme: .init())
    #if canImport(Prefire)
        .snapshot(delay: 0.5)
    #endif
}

#Preview("HouseworkTemplateTutorialView_自動で並ぶ") {
    HouseworkTemplateTutorialView(step: .autoPlacement, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .apply(theme: .init())
    #if canImport(Prefire)
        .snapshot(delay: 0.5)
    #endif
}

#Preview("HouseworkTemplateTutorialView_保存") {
    HouseworkTemplateTutorialView(step: .save, onTapNext: {}, onTapBack: {}, onTapClose: {})
        .apply(theme: .init())
    #if canImport(Prefire)
        .snapshot(delay: 0.5)
    #endif
}
#endif
