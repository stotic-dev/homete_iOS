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
    let editorNames: [String]

    var body: some View {
        if editorNames.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: .space8) {
                HStack(spacing: .space8) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.onSubSurface)
                    Text("編集中: \(editorNames.joined(separator: ", "))")
                        .font(with: .caption)
                        .foregroundStyle(.onSubSurface)
                    Spacer(minLength: .zero)
                }
                if !editorNames.isEmpty, !bannerDismissedInSession {
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
                editorNames: ["Aさん", "Bさん"]
            )
            HouseworkTemplateEditorsLabel(
                bannerDismissedInSession: .constant(false),
                editorNames: []
            )
        }
        .padding()
    }
#endif
