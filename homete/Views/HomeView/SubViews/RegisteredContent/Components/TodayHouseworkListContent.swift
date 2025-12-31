//
//  TodayHouseworkListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct TodayHouseworkListContent: View {
    
    var body: some View {
        // TODO: 家事が設定されている場合は、家事の内容を表示する
        VStack(spacing: .space24) {
            Text("今日の家事リスト")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: .zero) {
                Text("家事がありません")
                    .font(with: .headLineS)
                Spacer()
                    .frame(height: .space8)
                Text("今日の家事を確認して、家事リストを設定しましょう！")
                    .font(with: .body)
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(height: .space24)
                Button("家事を設定する") {
                    // TODO: 家事設定画面へ遷移
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
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    TodayHouseworkListContent()
}
