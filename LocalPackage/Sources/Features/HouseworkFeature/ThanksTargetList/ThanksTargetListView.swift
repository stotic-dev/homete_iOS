//
//  ThanksTargetListView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ありがとうを伝えられる家事の一覧
///
/// 何を並べるかは呼び出し側が決め、この画面は渡された値を描いてタップを伝えるだけにする。
/// 選択モードでは、まだありがとうを送っていない家事を選んで一括でありがとうを送れる（家事ボードの複数選択と同じ操作）。
/// 末尾には、昨日より前の家事を並べる過去のありがとう漏れの一覧へのリンクを置く。
/// ホームの過去の促しを出し切った後も、過去の一覧に行けるようにするため。
struct ThanksTargetListView: View {

    let summary: ThanksPromptSummary
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
    /// 過去のありがとう漏れの一覧へのリンクをタップした
    let onTapPastList: () -> Void
    /// 選択した家事へ一括でありがとうを送るボタンをタップした
    let onTapBulkThanks: () -> Void

    var body: some View {
        contentView()
            // ホームからの遷移で地の色が変わらないよう、ホームと同じミルク色にする
            .background(.backgroundScreen)
            .navigationTitle(.localized("ありがとうを伝える"))
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

private extension ThanksTargetListView {

    var selection: ThanksTargetSelection {
        .init(items: summary.thankableItems, selectedIDs: selectedIDs, ownUserId: ownUserId)
    }

    @ViewBuilder
    func contentView() -> some View {
        if summary.thankableItems.isEmpty {
            VStack(spacing: .space16) {
                Text("ありがとうを伝えられる家事はありません", bundle: #bundle)
                    .font(with: .body)
                pastListLink()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: isSelecting ? $selectedIDs.animation() : .constant([])) {
                ForEach(summary.thankableItems) { item in
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
                pastListLink()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .space8)
                    // 選択の途中で別の画面へ移ると選択が宙に浮くため、選択モード中は押せなくする
                    .disabled(isSelecting)
                    .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSeparator(.hidden)
                #endif
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

    /// 過去のありがとう漏れの一覧へのリンク。今日の家事の邪魔をしないよう、控えめな見た目にする
    func pastListLink() -> some View {
        Button {
            onTapPastList()
        } label: {
            HStack(spacing: .space4) {
                Text("昨日までの家事を見る", bundle: #bundle)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
        }
        .buttonStyle(.plain)
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

}

#if DEBUG
extension ThanksPromptSummary {

    /// プレビュー用の、未送信と送信済みの家事が1件ずつある一覧
    static var previewSample: Self {
        let today = Date.previewDate(year: 2026, month: 5, day: 18)
        return .init(
            thankableItems: [
                .init(
                    originalItem: .makeForTest(
                        id: 1,
                        indexedDate: today,
                        title: "洗濯",
                        point: 20,
                        state: .completed,
                        executorId: "otherUserId",
                        executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 9)
                    ),
                    isRegistered: true
                ),
                .init(
                    originalItem: .makeForTest(
                        id: 2,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .completed,
                        executorId: "otherUserId",
                        executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 8),
                        thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
                    ),
                    isRegistered: true
                ),
            ],
            notSentCount: 1,
            executorNames: ["はなこ"]
        )
    }

}

extension CohabitantMemberList {

    /// プレビュー用の、自分と同居人1人のメンバー
    static var thanksTargetPreviewSample: Self {
        .init(
            value: [
                .init(id: "ownUserId", userName: "自分"),
                .init(id: "otherUserId", userName: "はなこ"),
            ],
            ownId: "ownUserId"
        )
    }

}

#Preview("ThanksTargetListView_未送信と送信済み") {
    NavigationStack {
        ThanksTargetListView(
            summary: .previewSample,
            ownUserId: "ownUserId",
            members: .thanksTargetPreviewSample,
            isSelecting: .constant(false),
            selectedIDs: .constant([]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapPastList: {},
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("ThanksTargetListView_選択モード") {
    NavigationStack {
        ThanksTargetListView(
            summary: .previewSample,
            ownUserId: "ownUserId",
            members: .thanksTargetPreviewSample,
            isSelecting: .constant(true),
            selectedIDs: .constant([]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapPastList: {},
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("ThanksTargetListView_選択中") {
    let summary = ThanksPromptSummary.previewSample
    NavigationStack {
        ThanksTargetListView(
            summary: summary,
            ownUserId: "ownUserId",
            members: .thanksTargetPreviewSample,
            isSelecting: .constant(true),
            selectedIDs: .constant([summary.thankableItems[0].id]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapPastList: {},
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("ThanksTargetListView_家事なし") {
    NavigationStack {
        ThanksTargetListView(
            summary: .init(thankableItems: [], notSentCount: 0, executorNames: []),
            ownUserId: "ownUserId",
            members: .init(value: [], ownId: "ownUserId"),
            isSelecting: .constant(false),
            selectedIDs: .constant([]),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapPastList: {},
            onTapBulkThanks: {}
        )
    }
    .setupEnvironmentForPreview()
}
#endif
