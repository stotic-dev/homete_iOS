//
//  HouseworkPointDashboardContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct HouseworkPointDashboardContent: View {
    
    let monthlyPoint: Int
    let thanksPoint: Int
    
    var body: some View {
        HStack(spacing: DesignSystem.Space.space16) {
            pointBox {
                Text("今月の獲得ポイント")
                    .font(with: .body)
                Text(monthlyPoint.formatted())
                    .font(with: .headLineM)
            }
            pointBox {
                Text("もらった感謝の数")
                    .font(with: .body)
                Text(thanksPoint.formatted())
                    .font(with: .headLineM)
            }
        }
        .frame(minHeight: 136)
    }
}

private extension HouseworkPointDashboardContent {
    
    func pointBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: DesignSystem.Space.space8) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            RoundedRectangle(radius: .radius8)
                .stroke(lineWidth: 2)
                .foregroundStyle(.primary1)
        }
    }
}

#Preview("各ポイントが1桁") {
    HouseworkPointDashboardContent(monthlyPoint: 0, thanksPoint: 0)
        .frame(height: 136)
        .padding()
}

#Preview("各ポイントが10桁") {
    HouseworkPointDashboardContent(
        monthlyPoint: 1000000000,
        thanksPoint: 1000000000
    )
    .frame(height: 136)
    .padding()
}
