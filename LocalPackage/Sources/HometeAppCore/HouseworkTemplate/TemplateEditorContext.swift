//
//  TemplateEditorContext.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/18.
//

import Foundation
import HometeDomain

public struct TemplateEditorContext: Equatable, Sendable {

    public let currentActiveEditors: [TemplateActiveEditor]
    public let currentTemplateVersion: Int

    public init(
        currentActiveEditors: [TemplateActiveEditor],
        currentTemplateVersion: Int
    ) {
        self.currentActiveEditors = currentActiveEditors
        self.currentTemplateVersion = currentTemplateVersion
    }

    public func applyEditors(editors: [HouseworkTemplateEditor], members: CohabitantMemberList, now: Date) -> Self {
        let activeEditors: [TemplateActiveEditor] = editors
            .filter { $0.isActive(now: now) }
            .compactMap {
                guard let userName = members.userName($0.userId) else { return nil }
                return .init(id: $0.userId, userName: userName)
            }
        return .init(currentActiveEditors: activeEditors, currentTemplateVersion: currentTemplateVersion)
    }

    public func applyEditors(_ version: Int) -> Self {
        .init(currentActiveEditors: currentActiveEditors, currentTemplateVersion: version)
    }

}
