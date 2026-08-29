//
//  LicenseListView.swift
//  homete
//

import HometeUI
import SwiftUI

struct LicenseListView: View {

    @Environment(\.settingNavigationPath) var navigationPath

    var body: some View {
        List {
            ForEach(OSSLicense.all) { license in
                licenseRow(license)
            }
        }
        .listStyle(.plain)
        .navigationTitle("ライセンス")
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
    }

}

private extension LicenseListView {

    func licenseRow(_ license: OSSLicense) -> some View {
        Button {
            navigationPath.push(.licenseDetail(license))
        } label: {
            VStack(alignment: .leading, spacing: .space4) {
                Text(license.name)
                    .font(with: .body)
                Text(license.licenseType)
                    .font(with: .caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, .space8)
        }
    }

}

#Preview {
    NavigationStack {
        LicenseListView()
    }
}
