//
//  HouseworkItemPropertyListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import SwiftUI

struct HouseworkItemPropertyListContent: View {
    
    let item: HouseworkItem
    
    var body: some View {
        VStack(spacing: .zero) {
            houseworkPropertyRow("日付") {
                Text(item.formattedIndexedDate)
                    .font(with: .headLineS)
            }
            Divider()
            houseworkPropertyRow("ポイント") {
                Text("\(item.point)pt")
                    .font(with: .headLineS)
            }
            if let executedAt = item.executedAt {
                Divider()
                houseworkPropertyRow("完了時間") {
                    Text(executedAt, style: .time)
                        .font(with: .headLineS)
                }
            }
        }
    }
}

private extension HouseworkItemPropertyListContent {
    
    func houseworkPropertyRow(_ title: String, detailContent: () -> some View) -> some View {
        HStack(spacing: .zero) {
            Text(title)
                .font(with: .body)
                .foregroundStyle(.primary2)
            Spacer()
            detailContent()
        }
        .padding(.space24)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HouseworkItemPropertyListContent(item: .init(
        id: "",
        title: "洗濯",
        point: 10,
        metaData: .init(
            indexedDate: .init(value: "2026/1/1"),
            expiredAt: .init(timeIntervalSince1970: 0)
        ),
        executedAt: .distantFuture
    ))
    .setupEnvironmentForPreview()
}
