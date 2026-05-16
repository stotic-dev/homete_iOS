//
//  HouseworkTemplateItemRow.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkTemplateItemRow: View {

    let item: HouseworkTemplateItem

    var body: some View {
        HStack(spacing: .space8) {
            Text(item.title)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            PointLabel(point: item.point)
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(radius: .radius8)
                .fill(.surface)
        }
    }

}

#if DEBUG
    #Preview(traits: .sizeThatFitsLayout) {
        HouseworkTemplateItemRow(
            item: .init(
                id: .init(id: "1"),
                title: "洗濯",
                point: 10,
                updatedAt: .distantPast
            )
        )
        .padding()
    }
#endif
