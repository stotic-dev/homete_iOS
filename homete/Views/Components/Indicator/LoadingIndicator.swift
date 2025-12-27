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
            Indicator()
        }
        .ignoresSafeArea()
    }
}

extension View {
    func fullScreenLoadingIndicator(_ isLoading: Bool) -> some View {
        ZStack {
            self
            if isLoading {
                LoadingIndicator()
            }
        }
    }
}

#Preview {
    LoadingIndicator()
}
