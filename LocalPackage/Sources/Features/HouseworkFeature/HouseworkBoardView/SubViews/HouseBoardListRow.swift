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

public struct HouseBoardListRow: View {

    let houseworkItem: HouseworkItem
    let completionInfo: CompletionInfo?
    let onTapThanks: (() -> Void)?

    /// - Parameters:
    ///   - completionInfo: 家事ボードの完了リストでだけ渡す、担当者とありがとうの状況
    ///   - onTapThanks: ハートのタップでありがとうを伝えられるときだけ渡す
    public init(
        houseworkItem: HouseworkItem,
        completionInfo: CompletionInfo? = nil,
        onTapThanks: (() -> Void)? = nil
    ) {
        self.houseworkItem = houseworkItem
        self.completionInfo = completionInfo
        self.onTapThanks = onTapThanks
    }

    public var body: some View {
        HStack(spacing: .space16) {
            PointLabel(point: houseworkItem.earnedPoint)
            VStack(alignment: .leading, spacing: .space4) {
                Text(houseworkItem.title)
                    .font(with: .body)
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
        .tag(houseworkItem.id)
    }

}

public extension HouseBoardListRow {

    /// 完了リストの家事セルに出す、担当者とありがとうの状況
    struct CompletionInfo: Equatable {

        /// 家事を終えた人の名前。グループを抜けたなどで分からない人は含めない
        let executorNames: [String]
        let thanksStatus: HouseworkThanksStatus?

        /// 担当者の表示。複数人で担当した家事は「・」でつなぐ。名前が1人も分からなければ`nil`
        var executorLabel: String? {
            guard !executorNames.isEmpty else { return nil }

            return executorNames.map { "\($0)さん" }.joined(separator: "・")
        }

    }

}

private extension HouseBoardListRow {

    func metaDataLabel(_ metaData: HouseworkItemMetaData) -> some View {
        Label(metaData.label, systemImage: metaData.systemImage)
            .font(with: .boldCaption)
            .foregroundStyle(metaData.foregroundStyle)
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
                Text("ありがとうが届きました")
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

    func thanksAccessibilityLabel(_ status: HouseworkThanksStatus) -> String {
        switch status {
        case .notSent:
            "まだありがとうを伝えていません"
        case .sent:
            "ありがとうを伝えました"
        case .received:
            "ありがとうが届きました"
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
        .accessibilityLabel("ありがとうを伝える")
    }

}

#if DEBUG
#Preview("HouseBoardListRow_未完了", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1))
        )
    )
}

#Preview("HouseBoardListRow_完了", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "otherUserId"
        )
    )
}

#Preview("HouseBoardListRow_完了_ありがとう未送信", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "otherUserId"
        ),
        completionInfo: .init(executorNames: ["はなこ"], thanksStatus: .notSent),
        onTapThanks: {}
    )
}

#Preview("HouseBoardListRow_完了_ありがとう送信済み", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "otherUserId"
        ),
        completionInfo: .init(executorNames: ["はなこ"], thanksStatus: .sent)
    )
}

#Preview("HouseBoardListRow_完了_ありがとう受信", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "ownUserId"
        ),
        completionInfo: .init(executorNames: ["たろう"], thanksStatus: .received)
    )
}

#Preview("HouseBoardListRow_完了_自分_ありがとうなし", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executorId: "ownUserId"
        ),
        completionInfo: .init(executorNames: ["たろう"], thanksStatus: nil)
    )
}

#Preview("HouseBoardListRow_完了_複数人で担当", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .completed,
            executors: [
                .init(userId: "ownUserId", percentage: 50, point: 10),
                .init(userId: "otherUserId", percentage: 50, point: 10),
            ]
        ),
        completionInfo: .init(executorNames: ["たろう", "はなこ"], thanksStatus: .notSent)
    )
}

#Preview("HouseBoardListRow_やらない", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .notTodo
        )
    )
}
#endif
