//
//  HouseBoardListRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/28.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事の一覧に並べる1行
///
/// 行の内容と、右端に並ぶ完了・その他のボタンをまとめて持つ。行のタップ（詳細への遷移）と
/// ボタンのタップが競合しないよう、ボタンは行の`Button`の**中ではなく隣**に置いている。
///
/// どのボタンを出すか・ありがとうを伝えられるかは画面ごとに違うため、この行では判断せず決まった値を
/// 受け取る。`@Environment`に依存しないので、プレビューで表示のバリエーションを並べられる。
public struct HouseBoardListRow<MenuContent: View>: View {

    let houseworkItem: HouseworkItem
    let completionInfo: HouseworkRowCompletionInfo?
    let showsCompleteButton: Bool
    let showsMoreButton: Bool
    let onTapRow: () -> Void
    let onTapThanks: (() -> Void)?
    let onTapComplete: () -> Void
    let menuContent: () -> MenuContent

    /// - Parameters:
    ///   - completionInfo: 家事ボードの完了リストでだけ渡す、担当者とありがとうの状況。他の画面では`nil`
    ///   - showsCompleteButton: 完了ボタンを出すかどうか（未完了の家事だけ）
    ///   - showsMoreButton: その他ボタンを出すかどうか（メニューに出せるアクションが無いときは出さない）
    ///   - onTapThanks: ハートのタップでありがとうを伝えられるときだけ渡す
    ///   - menuContent: その他ボタンのメニューの中身。`HouseworkQuickActionMenuContent`を渡す
    public init(
        houseworkItem: HouseworkItem,
        completionInfo: HouseworkRowCompletionInfo?,
        showsCompleteButton: Bool,
        showsMoreButton: Bool,
        onTapRow: @escaping () -> Void,
        onTapThanks: (() -> Void)?,
        onTapComplete: @escaping () -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.houseworkItem = houseworkItem
        self.completionInfo = completionInfo
        self.showsCompleteButton = showsCompleteButton
        self.showsMoreButton = showsMoreButton
        self.onTapRow = onTapRow
        self.onTapThanks = onTapThanks
        self.onTapComplete = onTapComplete
        self.menuContent = menuContent
    }

    public var body: some View {
        HStack(spacing: .space8) {
            Button(action: onTapRow) {
                rowContent()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            HouseworkRowActionButtons(
                showsCompleteButton: showsCompleteButton,
                showsMoreButton: showsMoreButton,
                onTapComplete: onTapComplete,
                menuContent: menuContent
            )
        }
        .tag(houseworkItem.id)
    }

}

/// 完了リストの家事セルに出す、担当者とありがとうの状況
public struct HouseworkRowCompletionInfo: Equatable {

    /// 家事を終えた人の名前。グループを抜けたなどで分からない人は含めない
    let executorNames: [String]
    let thanksStatus: HouseworkThanksStatus?

    /// 担当者の表示。複数人で担当した家事は「・」でつなぐ。名前が1人も分からなければ`nil`
    var executorLabel: String? {
        guard !executorNames.isEmpty else { return nil }

        return executorNames
            .map { LocalizedStringResource.localized("\($0)さん", comment: "担当者の名前に付ける敬称").resolved() }
            .joined(separator: LocalizedStringResource.localized("・", comment: "担当者の名前を並べるときの区切り").resolved())
    }

}

private extension HouseBoardListRow {

    func rowContent() -> some View {
        HStack(spacing: .space16) {
            PointLabel(point: houseworkItem.earnedPoint)
            VStack(alignment: .leading, spacing: .space4) {
                HStack(spacing: .space4) {
                    Text(houseworkItem.title)
                        .font(with: .body)
                    // 本文は詳細画面で見るので、一覧ではメモがあることだけを示す
                    if houseworkItem.memo.hasContent {
                        memoIndicator()
                    }
                }
                if let label = completionInfo?.executorLabel {
                    executorLabel(label)
                } else if let metaData = HouseworkItemMetaData.make(item: houseworkItem) {
                    metaDataLabel(metaData)
                }
            }
            Spacer()
            if let thanksStatus = completionInfo?.thanksStatus {
                if let onTapThanks {
                    thanksButton(thanksStatus, action: onTapThanks)
                } else {
                    thanksStatusLabel(thanksStatus)
                }
            }
        }
    }

    func metaDataLabel(_ metaData: HouseworkItemMetaData) -> some View {
        Label(metaData.label, systemImage: metaData.systemImage)
            .font(with: .boldCaption)
            .foregroundStyle(metaData.foregroundStyle)
    }

    func memoIndicator() -> some View {
        Image(systemName: "note.text")
            .font(with: .caption)
            .foregroundStyle(.onSurfaceVariant)
            .accessibilityLabel(.localized("メモあり"))
    }

    func executorLabel(_ label: String) -> some View {
        Label(label, systemImage: "person.fill")
            .font(with: .boldCaption)
            .foregroundStyle(.onSubSurface)
    }

    func thanksStatusLabel(_ status: HouseworkThanksStatus) -> some View {
        HStack(spacing: .space4) {
            Image(systemName: thanksSystemImage(status))
            // アイコンだけで伝わらない、ありがとうが届いたことだけ文言を添える
            if status == .received {
                Text("ありがとうが届きました", bundle: #bundle)
                    .font(with: .boldCaption)
            }
        }
        .foregroundStyle(thanksForegroundStyle(status))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(thanksAccessibilityLabel(status))
    }

    func thanksSystemImage(_ status: HouseworkThanksStatus) -> String {
        switch status {
        case .notSent:
            "heart"
        case .sent, .received:
            "heart.fill"
        }
    }

    /// 伝え終えた家事は、赤ピンクのハートで伝えたことがひと目で分かるようにする
    func thanksForegroundStyle(_ status: HouseworkThanksStatus) -> Color {
        switch status {
        case .notSent, .received:
            .accent
        case .sent:
            .thanksHeart
        }
    }

    func thanksAccessibilityLabel(_ status: HouseworkThanksStatus) -> LocalizedStringResource {
        switch status {
        case .notSent:
            .localized("まだありがとうを伝えていません")
        case .sent:
            .localized("ありがとうを伝えました")
        case .received:
            .localized("ありがとうが届きました")
        }
    }

    /// セル全体のタップ（詳細への遷移）とは別に、ハートだけで反応するボタン
    func thanksButton(_ status: HouseworkThanksStatus, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            thanksStatusLabel(status)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(.localized("ありがとうを伝える"))
        .tutorialSpotlightTarget(.houseworkThanksButton)
    }

}

#if DEBUG
#Preview("HouseBoardListRow_未完了", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20),
        completionInfo: nil,
        showsCompleteButton: true,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_未完了_メモあり", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "買い出し",
            point: 20,
            memo: .init(text: "", checklist: [.init(id: "1", title: "牛乳", isChecked: false)])
        ),
        completionInfo: nil,
        showsCompleteButton: true,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .completed, executorId: "otherUserId"),
        completionInfo: nil,
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了_ありがとう未送信", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .completed, executorId: "otherUserId"),
        completionInfo: .init(executorNames: ["はなこ"], thanksStatus: .notSent),
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: {},
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了_ありがとう送信済み", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .completed, executorId: "otherUserId"),
        completionInfo: .init(executorNames: ["はなこ"], thanksStatus: .sent),
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了_ありがとう受信", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .completed, executorId: "ownUserId"),
        completionInfo: .init(executorNames: ["たろう"], thanksStatus: .received),
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了_自分_ありがとうなし", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .completed, executorId: "ownUserId"),
        completionInfo: .init(executorNames: ["たろう"], thanksStatus: nil),
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

#Preview("HouseBoardListRow_完了_複数人で担当", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            state: .completed,
            executors: [
                .init(userId: "ownUserId", percentage: 50, point: 10),
                .init(userId: "otherUserId", percentage: 50, point: 10),
            ]
        ),
        completionInfo: .init(executorNames: ["たろう", "はなこ"], thanksStatus: .notSent),
        showsCompleteButton: false,
        showsMoreButton: true,
        onTapRow: {},
        onTapThanks: {},
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

// やらないにした家事は、メニューに出せるアクションが1つも無いのでボタンが並ばない
#Preview("HouseBoardListRow_やらない", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20, state: .notTodo),
        completionInfo: nil,
        showsCompleteButton: false,
        showsMoreButton: false,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}

// 選択モード中は、行のタップで選ぶことを優先してボタンを出さない
#Preview("HouseBoardListRow_未完了_ボタンなし", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(title: "洗濯", point: 20),
        completionInfo: nil,
        showsCompleteButton: false,
        showsMoreButton: false,
        onTapRow: {},
        onTapThanks: nil,
        onTapComplete: {},
        menuContent: { EmptyView() }
    )
}
#endif
