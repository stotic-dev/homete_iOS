//
//  FrequentHouseworkEmptyView.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// いつもの家事が1件もないときの表示
struct FrequentHouseworkEmptyView: View {

    let onTapAdd: () -> Void

    var body: some View {
        VStack(spacing: .space24) {
            Image(systemName: "star.square.on.square")
                .font(.system(size: 48))
                .foregroundStyle(.decorativeIcon)
            VStack(spacing: .space8) {
                Text("いつもの家事を登録しませんか？")
                    .font(with: .headLineS)
                Text("よくやる家事を登録しておくと、次からタップするだけで追加できます。")
                    .font(with: .body)
                    .multilineTextAlignment(.center)
            }
            Button("いつもの家事を追加する") {
                onTapAdd()
            }
            .primaryButtonStyle()
        }
        .padding(.horizontal, .space16)
    }

}

#if DEBUG
#Preview("FrequentHouseworkEmptyView") {
    FrequentHouseworkEmptyView(onTapAdd: {})
}
#endif
