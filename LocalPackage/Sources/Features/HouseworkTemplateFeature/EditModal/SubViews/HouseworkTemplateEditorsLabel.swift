//
//  HouseworkTemplateEditorsLabel.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeUI
import SwiftUI

struct HouseworkTemplateEditorsLabel: View {

    let editorNames: [String]

    var body: some View {
        if editorNames.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: .space8) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.onSubSurface)
                Text("編集中: \(editorNames.joined(separator: ", "))")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
                Spacer(minLength: .zero)
            }
        }
    }

}

#if DEBUG
    #Preview {
        VStack(alignment: .leading) {
            HouseworkTemplateEditorsLabel(editorNames: ["Aさん", "Bさん"])
            HouseworkTemplateEditorsLabel(editorNames: [])
        }
        .padding()
    }
#endif
