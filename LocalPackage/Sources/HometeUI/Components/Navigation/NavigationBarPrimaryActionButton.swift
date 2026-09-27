//
//  NavigationBarPrimaryActionButton.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import SwiftUI

public struct NavigationBarPrimaryActionButton: View {

    /// ボタンに出す内容
    enum Content {

        /// アイコンだけ
        case systemImage(String)
        /// アイコンと文字。件数など、アイコンだけでは伝えられない情報があるとき
        case titleAndSystemImage(title: String, systemImage: String)

    }

    let content: Content
    public let action: () -> Void

    public init(systemImage: String, action: @escaping () -> Void) {
        content = .systemImage(systemImage)
        self.action = action
    }

    public init(title: String, systemImage: String, action: @escaping () -> Void) {
        content = .titleAndSystemImage(title: title, systemImage: systemImage)
        self.action = action
    }

    public var body: some View {
        Group {
            #if os(iOS)
            if #available(iOS 26.0, *) {
                confirmRoleButton()
            } else {
                basicButton()
            }
            #else
            basicButton()
            #endif
        }
        .tint(.accent)
    }

}

private extension NavigationBarPrimaryActionButton {

    #if os(iOS)
    @available(iOS 26.0, *)
    @ViewBuilder
    func confirmRoleButton() -> some View {
        switch content {
        case let .systemImage(systemImage):
            Button("", systemImage: systemImage, role: .confirm) {
                action()
            }

        case let .titleAndSystemImage(title, systemImage):
            Button(title, systemImage: systemImage, role: .confirm) {
                action()
            }
            // ツールバーの既定はアイコンだけの表示になるため、文字も出す
            .labelStyle(.titleAndIcon)
        }
    }
    #endif

    func basicButton() -> some View {
        Button {
            action()
        } label: {
            switch content {
            case let .systemImage(systemImage):
                Image(systemName: systemImage)

            case let .titleAndSystemImage(title, systemImage):
                Label(title, systemImage: systemImage)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

}
