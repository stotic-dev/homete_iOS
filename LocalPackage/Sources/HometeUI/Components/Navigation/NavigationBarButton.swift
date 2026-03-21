//
//  NavigationBarButton.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

public struct NavigationBarButton: View {

    public let label: NavigationBarContentLabel
    public let action: () -> Void

    public init(label: NavigationBarContentLabel, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            label.icon
                .padding(.space8)
                .foregroundStyle(.onSurface)
        }
    }
}
