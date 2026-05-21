//
//  HouseworkTemplateEditorsLabel.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeUI
import SwiftUI

struct HouseworkTemplateEditorsLabel: View {

    @Binding var bannerDismissedInSession: Bool
    let activeEditors: [TemplateActiveEditor]

    var body: some View {
        if activeEditors.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: .space8) {
                HStack(spacing: .space8) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.onSubSurface)
                    Text("編集中: \(activeEditors.map(\.userName).joined(separator: ", "))")
                        .font(with: .caption)
                        .foregroundStyle(.onSubSurface)
                    Spacer(minLength: .zero)
                }
                if !bannerDismissedInSession {
                    HouseworkTemplateConflictBanner {
                        withAnimation {
                            bannerDismissedInSession = true
                        }
                    }
                }
            }
        }
    }

}

#if DEBUG
#Preview(traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading) {
        HouseworkTemplateEditorsLabel(
            bannerDismissedInSession: .constant(false),
            activeEditors: [
                .init(id: "1", userName: "Aさん"),
                .init(id: "2", userName: "Bさん"),
            ]
        )
        HouseworkTemplateEditorsLabel(
            bannerDismissedInSession: .constant(false),
            activeEditors: []
        )
    }
    .padding()
}
#endif
