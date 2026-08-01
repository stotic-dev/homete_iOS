//
//  TemplateEditorContextTest.swift
//  HouseworkTemplateFeatureTests
//
//  Created by Taichi Sato on 2026/05/20.
//

import Foundation
@testable import HometeDomain
@testable import HouseworkTemplateFeature
import Testing

enum TemplateEditorContextTest {

    static let ownUserId = "ownUserId"
    static let otherUserId1 = "otherUserId1"
    static let otherUserId2 = "otherUserId2"

    static let memberList = CohabitantMemberList(
        value: [
            .init(id: ownUserId, userName: "オーナー"),
            .init(id: otherUserId1, userName: "Aさん"),
            .init(id: otherUserId2, userName: "Bさん"),
        ],
        ownId: ownUserId
    )

    struct ApplyEditorsWithListCase {}
    struct ApplyEditorsWithVersionCase {}

}

private typealias TestCase = TemplateEditorContextTest

extension TemplateEditorContextTest.ApplyEditorsWithListCase {

    @Test("アクティブな編集者のうち、メンバー一覧に存在するユーザーをcurrentActiveEditorsに反映する")
    func reflectsActiveEditorsThatExistInMembers() {
        // Arrange
        let now = Date(timeIntervalSince1970: 1_000_000)
        let editors: [HouseworkTemplateEditor] = [
            .init(
                userId: TestCase.otherUserId1,
                updatedAt: now,
                expiredAt: now.addingTimeInterval(300)
            ),
            .init(
                userId: TestCase.otherUserId2,
                updatedAt: now,
                expiredAt: now.addingTimeInterval(300)
            ),
        ]
        let context = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 3
        )
        let expected = TemplateEditorContext(
            currentActiveEditors: [
                .init(id: TestCase.otherUserId1, userName: "Aさん"),
                .init(id: TestCase.otherUserId2, userName: "Bさん"),
            ],
            currentTemplateVersion: 3
        )

        // Act
        let actual = context.applyEditors(
            editors: editors,
            members: TestCase.memberList,
            now: now
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("離席済み（updatedAtが5分以上古い）の編集者はcurrentActiveEditorsに含まれない")
    func excludesInactiveEditors() {
        // Arrange
        let now = Date(timeIntervalSince1970: 1_000_000)
        let inactiveUpdatedAt = now.addingTimeInterval(-5 * 60)
        let editors: [HouseworkTemplateEditor] = [
            .init(
                userId: TestCase.otherUserId1,
                updatedAt: inactiveUpdatedAt,
                expiredAt: inactiveUpdatedAt.addingTimeInterval(300)
            ),
        ]
        let context = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 0
        )
        let expected = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 0
        )

        // Act
        let actual = context.applyEditors(
            editors: editors,
            members: TestCase.memberList,
            now: now
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("メンバー一覧に存在しないユーザーはcurrentActiveEditorsに含まれない")
    func excludesEditorsNotInMembers() {
        // Arrange
        let now = Date(timeIntervalSince1970: 1_000_000)
        let editors: [HouseworkTemplateEditor] = [
            .init(
                userId: "unknownUser",
                updatedAt: now,
                expiredAt: now.addingTimeInterval(300)
            ),
        ]
        let context = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 0
        )
        let expected = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 0
        )

        // Act
        let actual = context.applyEditors(
            editors: editors,
            members: TestCase.memberList,
            now: now
        )

        // Assert
        #expect(actual == expected)
    }

    @Test("editorsが空配列の場合、currentActiveEditorsは空のまま、currentTemplateVersionは保持される")
    func emptyEditorsKeepsVersion() {
        // Arrange
        let now = Date(timeIntervalSince1970: 1_000_000)
        let context = TemplateEditorContext(
            currentActiveEditors: [
                .init(id: TestCase.otherUserId1, userName: "Aさん"),
            ],
            currentTemplateVersion: 7
        )
        let expected = TemplateEditorContext(
            currentActiveEditors: [],
            currentTemplateVersion: 7
        )

        // Act
        let actual = context.applyEditors(
            editors: [],
            members: TestCase.memberList,
            now: now
        )

        // Assert
        #expect(actual == expected)
    }

}

extension TemplateEditorContextTest.ApplyEditorsWithVersionCase {

    @Test("バージョンを指定すると、currentTemplateVersionだけが更新される")
    func updatesOnlyVersion() {
        // Arrange
        let context = TemplateEditorContext(
            currentActiveEditors: [
                .init(id: TestCase.otherUserId1, userName: "Aさん"),
            ],
            currentTemplateVersion: 1
        )
        let expected = TemplateEditorContext(
            currentActiveEditors: [
                .init(id: TestCase.otherUserId1, userName: "Aさん"),
            ],
            currentTemplateVersion: 5
        )

        // Act
        let actual = context.applyEditors(5)

        // Assert
        #expect(actual == expected)
    }

}
