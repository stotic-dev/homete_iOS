//
//  TemplateEditorContext.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/18.
//

struct TemplateEditorContext: Equatable {

    let currentActiveEditors: [TemplateActiveEditor]
    let currentTemplateVersion: Int

    func applyEditors(editors: [HouseworkTemplateEditor], members: CohabitantMemberList, now: Date) -> Self {
        let activeEditors: [TemplateActiveEditor] = editors
            .filter { $0.isActive(now: now) }
            .compactMap {
                guard let userName = members.userName($0.userId) else { return nil }
                return .init(id: $0.userId, userName: userName)
            }
        return .init(currentActiveEditors: activeEditors, currentTemplateVersion: currentTemplateVersion)
    }

    func applyEditors(_ version: Int) -> Self {
        .init(currentActiveEditors: currentActiveEditors, currentTemplateVersion: version)
    }

}
