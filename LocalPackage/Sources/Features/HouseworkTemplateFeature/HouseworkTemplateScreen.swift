//
//  HouseworkTemplateScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import HometeUI
import SwiftUI

public struct HouseworkTemplateScreen: View {

    @Environment(\.dismiss) var dismiss

    public static func make() -> some View {
        HouseworkTemplateScreen()
    }

    public var body: some View {
        NavigationStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .navigationTitle("家事テンプレート")
                .inlineNavigationBarTitleDisplayMode()
                .leadingToolbarItem {
                    NavigationBarButton(label: .close) {
                        dismiss()
                    }
                }
        }
    }

}

#Preview {
    HouseworkTemplateScreen.make()
}
