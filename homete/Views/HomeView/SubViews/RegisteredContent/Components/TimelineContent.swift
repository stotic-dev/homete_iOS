//
//  TimelineContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct TimelineContent: View {
    var body: some View {
        VStack(spacing: .space24) {
            Text("タイムライン")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: .zero) {
                Text("まだアクティビティがありません")
                    .font(with: .headLineS)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .space56)
            .overlay {
                RoundedRectangle(radius: .radius8)
                    .stroke(style: .init(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.primary1)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    TimelineContent()
        .padding()
}
