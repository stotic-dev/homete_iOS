//
//  TutorialStep.swift
//  LocalPackage
//

/// チュートリアルのステップ
/// - Note: `allCases`の並び順がそのまま表示順になる
public protocol TutorialStep: CaseIterable, Equatable, Sendable where AllCases == [Self] {}

public extension TutorialStep {

    /// 何番目のステップか（0始まり）
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// 次のステップ。最後のステップならnil
    var next: Self? {
        let nextIndex = index + 1
        return Self.allCases.indices.contains(nextIndex) ? Self.allCases[nextIndex] : nil
    }

    /// 前のステップ。最初のステップならnil
    var previous: Self? {
        let previousIndex = index - 1
        return Self.allCases.indices.contains(previousIndex) ? Self.allCases[previousIndex] : nil
    }

}
