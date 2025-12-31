//
//  PointLabel.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/11.
//

import SwiftUI

struct PointLabel: View {
    
    let point: Int
    
    var body: some View {
        Text(point.formatted())
            .font(with: .headLineM)
            .foregroundStyle(.onPrimary2)
            .padding(.space8)
            .frame(minWidth: 45)
            .background {
                GeometryReader {
                    RoundedRectangle(cornerRadius: $0.size.height / 2)
                        .fill(.primary2)
                }
            }
    }
}

#Preview("PointLabel_1桁", traits: .sizeThatFitsLayout) {
    PointLabel(point: 1)
}

#Preview("PointLabel_2桁", traits: .sizeThatFitsLayout) {
    PointLabel(point: 10)
}

#Preview("PointLabel_3桁", traits: .sizeThatFitsLayout) {
    PointLabel(point: 100)
}
