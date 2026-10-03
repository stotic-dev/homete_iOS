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

    /// 画面内のセクションをカードとして区切り、カードの中の何もない所をタップしたときの処理を付ける
    ///
    /// カードの中の入力欄やボタンの外側をタップしたら入力を終える、といった用途に使う。
    /// タップを受けるのはカードの背景なので、手前にある入力欄やボタンの操作は妨げない。
    func sectionCardStyle(onTapBackground: @escaping () -> Void) -> some View {
        padding(.space16)
            .background {
                RoundedRectangle(radius: .radius16)
                    .fill(.subSurface)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                    .onTapGesture(perform: onTapBackground)
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
