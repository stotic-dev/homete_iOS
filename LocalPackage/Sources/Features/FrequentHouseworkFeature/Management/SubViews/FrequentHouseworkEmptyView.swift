//
//  FrequentHouseworkEmptyView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事が1件もないときの表示
struct FrequentHouseworkEmptyView: View {

    let onTapAdd: () -> Void
    /// テンプレートから取り込む導線。テンプレートに家事がない場合は`nil`
    let onTapImport: (() -> Void)?

    var body: some View {
        VStack(spacing: .space24) {
            Image(systemName: "star.square.on.square")
                .font(.system(size: 48))
                .foregroundStyle(.decorativeIcon)
            VStack(spacing: .space8) {
                Text("いつもの家事を登録しませんか？", bundle: #bundle)
                    .font(with: .headLineS)
                Text("よくやる家事を登録しておくと、次からタップするだけで追加できます。", bundle: #bundle)
                    .font(with: .body)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: .space8) {
                Button(.localized("いつもの家事を追加する")) {
                    onTapAdd()
                }
                .primaryButtonStyle()
                if let onTapImport {
                    Button(.localized("テンプレートから取り込む")) {
                        onTapImport()
                    }
                    .subPrimaryButtonStyle()
                }
            }
        }
        .padding(.horizontal, .space16)
    }

}

#if DEBUG
#Preview("FrequentHouseworkEmptyView_追加のみ") {
    FrequentHouseworkEmptyView(onTapAdd: {}, onTapImport: nil)
}

#Preview("FrequentHouseworkEmptyView_テンプレートあり") {
    FrequentHouseworkEmptyView(onTapAdd: {}, onTapImport: {})
}
#endif
