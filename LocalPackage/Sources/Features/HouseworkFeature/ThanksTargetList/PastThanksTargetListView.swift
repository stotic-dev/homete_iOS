//
//  PastThanksTargetListView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 過去のありがとう漏れの一覧
///
/// 昨日から7日前までに同居人が終えた家事のうち、まだありがとうを伝えていないものを日付ごとに並べる。
/// 何を並べるかは呼び出し側が決め、この画面は渡された値を描いてタップを伝えるだけにする。
/// 選択モードでは、まだありがとうを送っていない家事を日付をまたいで選び、一括でありがとうを送れる
/// （今日の一覧・家事ボードの複数選択と同じ操作）。
struct PastThanksTargetListView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale

    let summary: PastThanksPromptSummary
    let ownUserId: String
    let members: CohabitantMemberList
    @Binding var isSelecting: Bool
    /// 選択中の家事のID
    ///
    /// 一括でありがとうを送るボタンはナビゲーションバー側に置いているため、選択の保持は呼び出し側が行う
    @Binding var selectedIDs: Set<String>
    /// 行をタップした（メッセージを添えてありがとうを伝える）
    let onTapRow: (HouseworkBoardItem) -> Void
    /// ハートをタップした（ありがとうだけを伝える）
    let onTapThanks: (HouseworkBoardItem) -> Void
    /// 選択した家事へ一括でありがとうを送るボタンをタップした
    let onTapBulkThanks: () -> Void

    var body: some View {
        contentView()
            // ホームからの遷移で地の色が変わらないよう、ホームと同じミルク色にする
            .background(.backgroundScreen)
            .navigationTitle(.localized("昨日までの家事"))
            .inlineNavigationBarTitleDisplayMode()
            .softTopScrollEdgeEffect()
            // 選択モード中は左上に選択をやめるボタンを置くため、戻るボタンは隠す
            .navigationBarBackButtonHidden(isSelecting)
            .leadingToolbarItem {
                if isSelecting {
                    cancelSelectingButton()
                }
            }
            .trailingToolbarItem {
                if !isSelecting {
                    // 選べる家事が無いのに選択モードへ入れても何もできないため、ボタンごと出さない
                    if selection.hasSelectableItems {
                        selectButton()
                    }
                } else if !selection.targets.isEmpty {
                    // 中身が空でもツールバーの項目を置くと背景だけが残るため、選ぶまでは何も置かない
                    HouseworkBulkActionToolbarContent(actions: [.sendThanks]) { _ in
                        onTapBulkThanks()
                    }
                }
            }
            // 選択モードの出入りで選択を持ち越さない
            .onChange(of: isSelecting) {
                selectedIDs = []
            }
    }

}

// MARK: UI定義

private extension PastThanksTargetListView {

    var selection: ThanksTargetSelection {
        .init(items: summary.dailyItems.flatMap(\.items), selectedIDs: selectedIDs, ownUserId: ownUserId)
    }

    @ViewBuilder
    func contentView() -> some View {
        if summary.dailyItems.isEmpty {
            Text("この1週間で、まだありがとうを伝えていない家事はありません", bundle: #bundle)
                .font(with: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .space16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: isSelecting ? $selectedIDs.animation() : .constant([])) {
                ForEach(summary.dailyItems) { dailyItems in
                    Section {
                        ForEach(dailyItems.items) { item in
                            let isSelectionDisabled = isSelecting && !selection.isSelectable(item)
                            houseworkItemRow(item)
                                // 選択モード中は行のどこをタップしても選択の切り替えにする。行のボタンが先にタップを受け取ると、
                                // `List`の選択に届かずメッセージを添えるハーフモーダルが開いてしまうため
                                .allowsHitTesting(!isSelecting)
                                .padding(.vertical, .space8)
                                .opacity(isSelectionDisabled ? 0.4 : 1)
                                .selectionDisabled(isSelectionDisabled)
                                .listRowBackground(Color.clear)
                            #if os(iOS)
                                .listRowSpacing(.zero)
                                .listRowSeparator(.hidden)
                            #endif
                        }
                    } header: {
                        Text(dailyItems.date.formatted(dateFormatStyle))
                            .font(with: .boldCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            #if os(iOS)
                .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            #endif
        }
    }

    func selectButton() -> some View {
        Button(.localized("選択")) {
            withAnimation {
                isSelecting = true
            }
        }
    }

    /// 選択モードを抜けるボタン。左上に置いて、選択モードに入っていること自体を分かりやすくする
    func cancelSelectingButton() -> some View {
        NavigationBarButton(label: .close) {
            withAnimation {
                isSelecting = false
            }
        }
        .accessibilityLabel(.localized("選択をやめる"))
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        let thanksStatus = HouseworkThanksStatus.make(item: item, ownUserId: ownUserId)
        return HouseBoardListRow(
            houseworkItem: item.originalItem,
            completionInfo: .init(
                executorNames: item.executors.compactMap { members.userName($0.userId) },
                thanksStatus: thanksStatus
            ),
            showsCompleteButton: false,
            // ありがとうを伝えるための一覧なので、ほかの操作は家事ボードや詳細に任せる
            showsMoreButton: false,
            onTapRow: { onTapRow(item) },
            // 選択モード中は行の選択を優先して、ハートからは送らせない
            onTapThanks: thanksStatus == .notSent && !isSelecting ? { onTapThanks(item) } : nil,
            onTapComplete: {},
            menuContent: { EmptyView() }
        )
    }

    /// セクションの見出しの日付（例: 10月5日(日)）。家事の日付は端末の暦で決めているので、同じ暦とタイムゾーンで書く
    var dateFormatStyle: Date.FormatStyle {
        var style = Date.FormatStyle.dateTime.month().day().weekday()
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        style.locale = locale
        return style
    }

}

#if DEBUG
extension PastThanksPromptSummary {

    /// プレビュー用の、昨日と3日前に未送信と送信済みの家事がある一覧
    static var previewSample: Self {
        let yesterday = Date.previewDate(year: 2026, month: 5, day: 17)
        let threeDaysAgo = Date.previewDate(year: 2026, month: 5, day: 15)
        return .init(
            dailyItems: [
                .init(date: yesterday, items: [
                    .init(
                        originalItem: .makeForTest(
                            id: 1,
                            indexedDate: yesterday,
                            title: "洗濯",
                            point: 20,
                            state: .completed,
                            executorId: "otherUserId",
                            executedAt: .previewDate(year: 2026, month: 5, day: 17, hour: 21)
                        ),
                        isRegistered: true
                    ),
                    .init(
                        originalItem: .makeForTest(
                            id: 2,
                            indexedDate: yesterday,
                            title: "掃除",
                            point: 30,
                            state: .completed,
                            executorId: "otherUserId",
                            executedAt: .previewDate(year: 2026, month: 5, day: 17, hour: 9),
                            thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
                        ),
                        isRegistered: true
                    ),
                ]),
                .init(date: threeDaysAgo, items: [
                    .init(
                        originalItem: .makeForTest(
                            id: 3,
                            indexedDate: threeDaysAgo,
                            title: "ゴミ出し",
                            point: 10,
                            state: .completed,
                            executorId: "otherUserId",
                            executedAt: .previewDate(year: 2026, month: 5, day: 15, hour: 7)
                        ),
                        isRegistered: true
                    ),
                ]),
            ],
            notSentCount: 2,
            executorNames: ["はなこ"]
        )
    }

}

#Preview("PastThanksTargetListView_日付ごと") {
    NavigationStack {
        PastThanksTargetListView(
            summary: .previewSample,
            ownUserId: "ownUserId",
            members: .thanksTargetPreviewSample,
            isSelecting: .constant(false),
            selectedIDs: .constant([]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("PastThanksTargetListView_選択中") {
    let summary = PastThanksPromptSummary.previewSample
    NavigationStack {
        PastThanksTargetListView(
            summary: summary,
            ownUserId: "ownUserId",
            members: .thanksTargetPreviewSample,
            isSelecting: .constant(true),
            // 日付をまたいで選べることが分かるよう、昨日と3日前の未送信の家事を選ぶ
            selectedIDs: .constant([summary.dailyItems[0].items[0].id, summary.dailyItems[1].items[0].id]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("PastThanksTargetListView_家事なし") {
    NavigationStack {
        PastThanksTargetListView(
            summary: .init(dailyItems: [], notSentCount: 0, executorNames: []),
            ownUserId: "ownUserId",
            members: .init(value: [], ownId: "ownUserId"),
            isSelecting: .constant(false),
            selectedIDs: .constant([]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}
#endif
