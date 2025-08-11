//
//  NavigationBarButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct NavigationBarButton: View {
    
    let label: NavigationBarContentLabel
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            label.icon
                .resizable()
                .frame(width: 24, height: 24)
                .padding(DesignSystem.Space.space8)
        }
    }
}
