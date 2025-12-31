//
//  HouseworkDetailItemRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/13.
//

import SwiftUI

struct HouseworkDetailItemRow<Content: View>: View {
    
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            Text(title)
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }
}
