//
//  LoadingIndicator.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import SwiftUI

struct LoadingIndicator: View {
    var body: some View {
        ZStack {
            Color(.loadingBg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            ProgressView()
                .padding(DesignSystem.Space.space16)
                .tint(.white)
                .background(.gray)
                .cornerRadius(.radius8)
        }
    }
}

#Preview {
    LoadingIndicator()
}
