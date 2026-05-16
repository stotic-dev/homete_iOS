//
//  HouseworkTemplateEmptyView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeUI
import SwiftUI

struct HouseworkTemplateEmptyView: View {

    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: .space24) {
            Image(systemName: "list.bullet.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.primary2)
            VStack(spacing: .space8) {
                Text("テンプレートが未登録です")
                    .font(with: .headLineM)
                Text("週単位で繰り返す家事を登録できます")
                    .font(with: .body)
                    .foregroundStyle(.onSubSurface)
                    .multilineTextAlignment(.center)
            }
            Button("テンプレートを作成する") {
                onCreate()
            }
            .primaryButtonStyle()
        }
        .padding(.horizontal, .space24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    HouseworkTemplateEmptyView(onCreate: {})
        .apply(theme: .init())
}
#endif
