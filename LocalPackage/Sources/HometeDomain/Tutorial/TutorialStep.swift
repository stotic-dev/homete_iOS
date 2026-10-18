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
        index(in: Self.allCases)
    }

    /// 次のステップ。最後のステップならnil
    var next: Self? {
        next(in: Self.allCases)
    }

    /// 前のステップ。最初のステップならnil
    var previous: Self? {
        previous(in: Self.allCases)
    }

    /// 出すステップのうち、何番目のステップか（0始まり）
    /// - Parameter steps: 今回出すステップ。画面の状態によって一部のステップを除くときに渡す
    func index(in steps: [Self]) -> Int {
        steps.firstIndex(of: self) ?? 0
    }

    /// 出すステップのうち、次のステップ。最後のステップならnil
    /// - Parameter steps: 今回出すステップ。画面の状態によって一部のステップを除くときに渡す
    func next(in steps: [Self]) -> Self? {
        let nextIndex = index(in: steps) + 1
        return steps.indices.contains(nextIndex) ? steps[nextIndex] : nil
    }

    /// 出すステップのうち、前のステップ。最初のステップならnil
    /// - Parameter steps: 今回出すステップ。画面の状態によって一部のステップを除くときに渡す
    func previous(in steps: [Self]) -> Self? {
        let previousIndex = index(in: steps) - 1
        return steps.indices.contains(previousIndex) ? steps[previousIndex] : nil
    }

}
