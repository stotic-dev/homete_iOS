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

    /// - Parameter completionInfo: 家事ボードの完了リストでだけ渡す、担当者とありがとうの状況
    public init(houseworkItem: HouseworkItem, completionInfo: CompletionInfo? = nil) {
        self.houseworkItem = houseworkItem
        self.completionInfo = completionInfo
    }

    public var body: some View {
        HStack(spacing: .space16) {
            PointLabel(point: houseworkItem.point)
            VStack(alignment: .leading, spacing: .space4) {
                Text(houseworkItem.title)
                    .font(with: .body)
                if let executorName = completionInfo?.executorName {
                    executorLabel(executorName)
                } else if let metaData = HouseworkItemMetaData.make(item: houseworkItem) {
                    metaDataLabel(metaData)
                }
            }
            Spacer()
            if let thanksStatus = completionInfo?.thanksStatus {
                thanksStatusLabel(thanksStatus)
            }
        }
        .tag(houseworkItem.id)
    }

}

public extension HouseBoardListRow {

    /// 完了リストの家事セルに出す、担当者とありがとうの状況
    struct CompletionInfo: Equatable {

        /// 家事を終えた人の名前。グループを抜けたなどで分からない場合は`nil`
        let executorName: String?
        let thanksStatus: HouseworkThanksStatus?

    }

}

private extension HouseBoardListRow {

    func metaDataLabel(_ metaData: HouseworkItemMetaData) -> some View {
        Label(metaData.label, systemImage: metaData.systemImage)
            .font(with: .boldCaption)
            .foregroundStyle(metaData.foregroundStyle)
    }

    func executorLabel(_ executorName: String) -> some View {
        Label("\(executorName)さん", systemImage: "person.fill")
            .font(with: .boldCaption)
            .foregroundStyle(.onSubSurface)
    }

    func thanksStatusLabel(_ status: HouseworkThanksStatus) -> some View {
        HStack(spacing: .space4) {
            Image(systemName: status.systemImage)
            if let label = status.label {
                Text(label)
                    .font(with: .boldCaption)
            }
        }
        .foregroundStyle(status.foregroundStyle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.accessibilityLabel)
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
        completionInfo: .init(executorName: "はなこ", thanksStatus: .notSent)
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
        completionInfo: .init(executorName: "はなこ", thanksStatus: .sent)
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
        completionInfo: .init(executorName: "たろう", thanksStatus: .received)
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
        completionInfo: .init(executorName: "たろう", thanksStatus: nil)
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
