---
paths:
  - "LocalPackage/Tests/**/*.swift"
---

# Swiftテスト実装ルール

Swiftのテストファイル（`*Test.swift` / `*Tests.swift` / `Tests/**/*.swift`）を新規作成・編集する前に、必ず `swift-test-implementation` スキルを参照すること。

実装パターン（Arrange/Act/Assert・confirmation・AsyncStream・モック）と規約の詳細は当該スキルに集約されている:
- `.claude/skills/swift-test-implementation/SKILL.md`

## 必須事項（違反禁止）

- **アサーションのルール（最優先）**: expected値はテスト対象（プロダクション）のロジックを使わず、ピュアな`.init(...)`または`makeForTest`で構築すること。プロパティ単体検証ではなく、戻り値型の全体比較（`#expect(actual == expected)`）を行うこと。
- 1テスト1Act原則
- テスト追加・修正後は `swift-code-verification` スキルに従い `swift test` を必ず実行
