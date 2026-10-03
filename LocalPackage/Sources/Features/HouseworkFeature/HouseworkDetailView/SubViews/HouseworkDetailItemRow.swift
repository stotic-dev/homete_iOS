//
//  HouseworkDetailItemRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/13.
//

import HometeUI
import SwiftUI

/// 家事詳細のセクションのカードに並べる1項目。左に項目名、右に値を出す
struct HouseworkDetailItemRow<Content: View>: View {

    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .space16) {
            Text(title)
                .font(with: .body)
                .foregroundStyle(.onSurface)
            Spacer(minLength: .zero)
            content()
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

}
