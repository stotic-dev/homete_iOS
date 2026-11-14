//
//  LicenseDetailView.swift
//  homete
//

import HometeModel
import HometeUI
import SwiftUI

public struct LicenseDetailView: View {

    let license: OSSLicense

    public init(
        license: OSSLicense
    ) {
        self.license = license
    }

    public var body: some View {
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
    }

}

#Preview {
    NavigationStack {
        LicenseDetailView(license: OSSLicense.all[0])
    }
}
