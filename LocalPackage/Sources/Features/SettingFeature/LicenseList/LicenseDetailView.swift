//
//  LicenseDetailView.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

struct LicenseDetailView: View {

    let license: OSSLicense

    var body: some View {
        ScrollView {
            Text(license.licenseText)
                .font(with: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.space16)
        }
        // ライセンス一覧からの遷移で地の色が変わらないよう、一覧と同じミルク色にする
        .background(.backgroundScreen)
        .navigationTitle(license.name)
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trackScreenView(.licenseDetail)
    }

}

#Preview {
    NavigationStack {
        LicenseDetailView(license: OSSLicense.all[0])
    }
}
