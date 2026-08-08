//
//  LicenseDetailView.swift
//  homete
//

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
        .navigationTitle(license.name)
        .inlineNavigationBarTitleDisplayMode()
    }

}

#Preview {
    NavigationStack {
        LicenseDetailView(license: OSSLicense.all[0])
    }
}
