//
//  HouseBoardListRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/28.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseBoardListRow: View {

    @Environment(\.loginContext) var loginContext

    let houseworkItem: HouseworkItem

    public init(houseworkItem: HouseworkItem) {
        self.houseworkItem = houseworkItem
    }

    public var body: some View {
        HStack(spacing: .space16) {
            PointLabel(point: houseworkItem.point)
            VStack(alignment: .leading, spacing: .space4) {
                Text(houseworkItem.title)
                    .font(with: .body)
                if let metaData = HouseworkItemMetaData.make(
                    item: houseworkItem,
                    ownUserId: loginContext.account.id
                ) {
                    metaDataLabel(metaData)
                }
            }
            Spacer()
        }
        .tag(houseworkItem.id)
    }

}

private extension HouseBoardListRow {

    func metaDataLabel(_ metaData: HouseworkItemMetaData) -> some View {
        Label(metaData.label, systemImage: metaData.systemImage)
            .font(with: .boldCaption)
            .foregroundStyle(metaData.foregroundStyle)
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
    .setupLoginContextForPreview()
}

#Preview("HouseBoardListRow_要確認", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .pendingApproval,
            executorId: "otherUserId"
        )
    )
    .setupLoginContextForPreview()
}

#Preview("HouseBoardListRow_相手の確認待ち", traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .makeForPreview(
            title: "洗濯",
            point: 20,
            indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
            state: .pendingApproval,
            executorId: "ownUserId"
        )
    )
    .setupLoginContextForPreview()
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
    .setupLoginContextForPreview()
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
    .setupLoginContextForPreview()
}
#endif
