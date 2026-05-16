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
                .foregroundStyle(.alert)
            Text("他のユーザーがテンプレートを編集中です。保存時にコンフリクトすると編集内容が消える場合があります。")
                .font(with: .caption)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.onSurface)
            }
            .buttonStyle(.plain)
        }
        .padding(.space16)
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.subSurface)
                .overlay {
                    RoundedRectangle(radius: .radius8)
                        .stroke(.alert, lineWidth: 1)
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
