//
//  HouseworkTemplateConflictBanner.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeUI
import SwiftUI

struct HouseworkTemplateConflictBanner: View {

    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.fillDestructive)
            Text("ほかのメンバーがテンプレートを編集しています。同時に保存すると、編集した内容が消えることがあります。", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius12)
                .fill(.backgroundCard)
                .overlay {
                    RoundedRectangle(radius: .radius12)
                        .stroke(.fillDestructive, lineWidth: 1)
                }
        }
    }

}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    HouseworkTemplateConflictBanner(onClose: {})
        .padding()
}
#endif
