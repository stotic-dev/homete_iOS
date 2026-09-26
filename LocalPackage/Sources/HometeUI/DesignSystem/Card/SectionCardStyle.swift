//
//  SectionCardStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/09/26.
//

import SwiftUI

public extension View {

    /// 画面内のセクションをカードとして区切る
    ///
    /// ライトモードでは画面背景と同じ白系の色になるため、影で境界を出す。
    func sectionCardStyle() -> some View {
        padding(.space16)
            .background {
                RoundedRectangle(radius: .radius16)
                    .fill(.subSurface)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            }
    }

}

#Preview("SectionCardStyle", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: .space8) {
        Text("セクションタイトル")
            .font(with: .headLineM)
        Text("セクションの内容")
            .font(with: .body)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .sectionCardStyle()
    .padding(.space16)
}
