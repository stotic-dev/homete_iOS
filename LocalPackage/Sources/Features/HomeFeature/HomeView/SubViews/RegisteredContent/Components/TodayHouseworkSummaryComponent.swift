//
//  TodayHouseworkSummaryComponent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/20.
//

import HometeDomain
import HometeResources
import HometeUI
import HouseworkFeature
import SwiftUI

struct TodayHouseworkSummaryComponent: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.now) var now
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(\.calendar) var calendar
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.registeredContentNavigationPath) var navigationPath

    @State var isPresentingRegister = false
    @CommonError var commonError

    static func make() -> some View {
        TodayHouseworkSummaryComponent()
    }

    var body: some View {
        contentView(summary: TodayHouseworkSummary.make(
            storedAllItems: houseworkListStore.items,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            now: now,
            calendar: calendar,
            storagePolicy: storagePolicy
        ))
        .sheet(isPresented: $isPresentingRegister) {
            RegisterHouseworkView.make(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: now,
                    items: [],
                    calendar: calendar,
                    storagePolicy: storagePolicy
                )
            )
        }
        .commonError(content: $commonError)
    }

}

// MARK: - UI定義

private extension TodayHouseworkSummaryComponent {

    func contentView(summary: TodayHouseworkSummary) -> some View {
        VStack(spacing: .space24) {
            Text("今日の家事サマリー")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            switch summary.displayState {
            case .empty:
                emptyContent()

            case .allCompleted:
                progressContent(progress: summary.progress)
                allCompletedContent()

            case .hasIncomplete:
                progressContent(progress: summary.progress)
                incompleteListContent(summary: summary)
            }
        }
    }

    func progressContent(progress: Double) -> some View {
        VStack(spacing: .space8) {
            HStack {
                Text("達成率")
                    .font(with: .body)
                Spacer()
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(with: .headLineS)
            }
            ProgressView(value: progress)
                .tint(.primary1)
        }
    }

    func emptyContent() -> some View {
        VStack(spacing: .zero) {
            Text("今日の家事がありません")
                .font(with: .headLineS)
            Spacer()
                .frame(height: .space8)
            Text("今日の家事を確認して、家事リストを設定しましょう！")
                .font(with: .body)
                .multilineTextAlignment(.center)
            Spacer()
                .frame(height: .space24)
            Button("家事を設定する") {
                isPresentingRegister = true
            }
            .primaryButtonStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space56)
        .overlay {
            RoundedRectangle(radius: .radius8)
                .stroke(style: .init(lineWidth: 2, dash: [8]))
                .foregroundStyle(.primary1)
        }
    }

    func allCompletedContent() -> some View {
        VStack(spacing: .space8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.primary1)
            Text("今日の家事は全て完了しました")
                .font(with: .headLineS)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space24)
    }

    func incompleteListContent(summary: TodayHouseworkSummary) -> some View {
        VStack(spacing: .space16) {
            ForEach(summary.displayIncompleteItems) { item in
                HouseBoardListRow(houseworkItem: item.originalItem)
                    .contextMenu {
                        HouseworkQuickActionMenuContent(
                            item: item,
                            onError: { commonError = .init(error: $0) }
                        )
                    }
            }
            if summary.hasMoreIncomplete {
                Button("もっと表示する") {
                    navigationPath.push(.incompleteHouseworkList)
                }
                .primaryButtonStyle()
            }
        }
    }

}

#if DEBUG
#Preview("TodayHouseworkSummaryComponent_家事なし") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryComponent()
            .padding(.horizontal, .space16)
    }
    .environment(\.now, today)
    .environment(HouseworkListStore())
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryComponent_全て完了") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryComponent()
            .padding(.horizontal, .space16)
    }
    .environment(\.now, today)
    .environment(
        HouseworkListStore(items: [
            .init(
                items: [
                    .makeForTest(
                        id: 1,
                        indexedDate: today,
                        title: "洗濯",
                        point: 20,
                        state: .completed
                    ),
                    .makeForTest(
                        id: 2,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .completed
                    ),
                ],
                metaData: .init(
                    indexedDate: .init(value: today),
                    expiredAt: .distantFuture
                )
            ),
        ])
    )
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryComponent_未完了4件以下") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryComponent()
            .padding(.horizontal, .space16)
    }
    .environment(\.now, today)
    .environment(
        HouseworkListStore(items: [
            .init(
                items: [
                    .makeForTest(
                        id: 1,
                        indexedDate: today,
                        title: "洗濯",
                        point: 20,
                        state: .incomplete
                    ),
                    .makeForTest(
                        id: 2,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .pendingApproval
                    ),
                    .makeForTest(
                        id: 3,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .completed
                    ),
                ],
                metaData: .init(
                    indexedDate: .init(value: today),
                    expiredAt: .distantFuture
                )
            ),
        ])
    )
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryComponent_未完了5件以上") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryComponent()
            .padding(.horizontal, .space16)
    }
    .environment(\.now, today)
    .environment(
        HouseworkListStore(items: [
            .init(
                items: [
                    .makeForTest(
                        id: 1,
                        indexedDate: today,
                        title: "洗濯",
                        point: 20,
                        state: .incomplete
                    ),
                    .makeForTest(
                        id: 2,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .pendingApproval
                    ),
                    .makeForTest(
                        id: 3,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .incomplete
                    ),
                    .makeForTest(
                        id: 4,
                        indexedDate: today,
                        title: "ゴミ出し",
                        point: 20,
                        state: .incomplete
                    ),
                    .makeForTest(
                        id: 5,
                        indexedDate: today,
                        title: "買い物",
                        point: 30,
                        state: .pendingApproval
                    ),
                    .makeForTest(
                        id: 6,
                        indexedDate: today,
                        title: "アイロン",
                        point: 30,
                        state: .incomplete
                    ),
                ],
                metaData: .init(
                    indexedDate: .init(value: today),
                    expiredAt: .distantFuture
                )
            ),
        ])
    )
    .setupEnvironmentForPreview()
}
#endif
