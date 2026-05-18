//
//  HouseworkTemplateScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkTemplateScreen: View {

    @Environment(\.houseworkTemplateContext.hasTemplate) var hasTemplate

    @State var initialDraft: HouseworkTemplateDraft = .init()

    public static func make() -> some View {
        HouseworkTemplateScreen()
    }

    public var body: some View {
        NavigationStack {
            HouseworkTemplateView(
                hasTemplate: hasTemplate,
                initialDraft: initialDraft,
                activeOtherEditorNames: []
            )
        }
    }

}
