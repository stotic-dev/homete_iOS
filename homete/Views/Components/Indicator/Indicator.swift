//
//  Indicator.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

struct Indicator: View {
    var body: some View {
        ProgressView()
            .padding(.space16)
            .tint(.commonBlack)
            .background(.primary3)
            .cornerRadius(.radius8)
    }
}
