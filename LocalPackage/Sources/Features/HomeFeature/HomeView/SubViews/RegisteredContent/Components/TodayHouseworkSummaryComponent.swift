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
    @Environment(\.calendar) var calendar
    @Environment(\.registeredContentNavigationPath) var navigationPath

    @State var isPresentingRegister = false

    static func make() -> some View {
        TodayHouseworkSummaryComponent()
    }

    var body: some View {
        contentView(summary: TodayHouseworkSummary.make(
            storedAllItems: houseworkListStore.items,
            now: now,
            calendar: calendar
        ))
        .sheet(isPresented: $isPresentingRegister) {
            RegisterHouseworkView.make(
                dailyHouseworkList: .makeInitialValue(
                    selectedDate: now,
                    items: [],
                    calendar: calendar
                )
            )
        }
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
                HouseBoardListRow(houseworkItem: item)
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
                        previewItem(id: "1", title: "洗濯", point: 20, indexedDate: today, state: .completed),
                        previewItem(id: "2", title: "掃除", point: 30, indexedDate: today, state: .completed),
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
                        previewItem(id: "1", title: "洗濯", point: 20, indexedDate: today),
                        previewItem(id: "2", title: "掃除", point: 30, indexedDate: today),
                        previewItem(id: "3", title: "料理", point: 50, indexedDate: today, state: .completed),
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
                        previewItem(id: "1", title: "洗濯", point: 20, indexedDate: today),
                        previewItem(id: "2", title: "掃除", point: 30, indexedDate: today),
                        previewItem(id: "3", title: "料理", point: 50, indexedDate: today),
                        previewItem(id: "4", title: "ゴミ出し", point: 10, indexedDate: today),
                        previewItem(id: "5", title: "買い物", point: 40, indexedDate: today),
                        previewItem(id: "6", title: "アイロン", point: 25, indexedDate: today, state: .completed),
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

    private func previewItem(
        id: String,
        title: String,
        point: Int,
        indexedDate: Date,
        state: HouseworkState = .incomplete
    ) -> HouseworkItem {
        .init(
            id: id,
            title: title,
            point: point,
            metaData: .init(
                indexedDate: .init(value: indexedDate),
                expiredAt: .distantFuture
            ),
            state: state
        )
    }
#endif
