//
//  TemplateActiveEditor.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/18.
//

public struct TemplateActiveEditor: Equatable, Sendable {

    public let id: String
    public let userName: String

    public init(
        id: String,
        userName: String
    ) {
        self.id = id
        self.userName = userName
    }

}
