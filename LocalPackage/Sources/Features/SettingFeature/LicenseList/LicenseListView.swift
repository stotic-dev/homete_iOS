//
//  LicenseListView.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

struct LicenseListView: View {

    @Environment(\.settingNavigationPath) var navigationPath

    var body: some View {
        List {
            ForEach(OSSLicense.all) { license in
                licenseRow(license)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        // 設定からの遷移で地の色が変わらないよう、設定と同じミルク色にする
        .scrollContentBackground(.hidden)
        .background(.backgroundScreen)
        .navigationTitle(.localized("ライセンス"))
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .trackScreenView(.licenseList)
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
