//
//  HouseworkDetailItemRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/13.
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事詳細のセクションのカードに並べる1項目。左に項目名、右に値を出す
public struct HouseworkDetailItemRow<Content: View>: View {

    let title: LocalizedStringResource
    @ViewBuilder let content: () -> Content

    public init(
        title: LocalizedStringResource,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .space16) {
            Text(title)
                .font(with: .body)
                .foregroundStyle(.textPrimary)
            Spacer(minLength: .zero)
            content()
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

}
