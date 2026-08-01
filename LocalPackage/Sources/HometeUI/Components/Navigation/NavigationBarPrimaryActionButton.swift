//
//  NavigationBarPrimaryActionButton.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import SwiftUI

public struct NavigationBarPrimaryActionButton: View {

    public let systemImage: String
    public let action: () -> Void

    public init(systemImage: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 26.0, *) {
                Button("", systemImage: systemImage, role: .confirm) {
                    action()
                }
            } else {
                basicButton()
            }
            #else
            basicButton()
            #endif
        }
        .tint(.primary1)
    }

}

private extension NavigationBarPrimaryActionButton {

    func basicButton() -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
        }
    }

}
