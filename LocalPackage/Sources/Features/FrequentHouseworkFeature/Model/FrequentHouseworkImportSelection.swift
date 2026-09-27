//
//  FrequentHouseworkImportSelection.swift
//  LocalPackage
//

import HometeDomain

/// テンプレートから取り込む家事の選択状態
/// - Note: 候補は名前で重複を除いてあるため、選択は名前で持つ
struct FrequentHouseworkImportSelection: Equatable {

    let selectedTitles: Set<String>

    init(selectedTitles: Set<String> = []) {
        self.selectedTitles = selectedTitles
    }

    /// 取り込む件数
    var selectedCount: Int {
        selectedTitles.count
    }

    /// チェックが入っている候補の名前
    /// - Note: すでに登録済みの候補は、操作できないチェック済みとして見せる
    func checkedTitles(in candidates: [FrequentHouseworkImportCandidate]) -> Set<String> {
        selectedTitles.union(candidates.filter(\.isAlreadyRegistered).map(\.title))
    }

    /// チェックを切り替える
    func toggling(
        _ candidate: FrequentHouseworkImportCandidate,
        remainingCount: Int?
    ) -> ToggleResult {
        guard !candidate.isAlreadyRegistered else { return .unavailable }
        if selectedTitles.contains(candidate.title) {
            return .changed(.init(selectedTitles: selectedTitles.subtracting([candidate.title])))
        }
        // 無料プランでは、上限までの残り件数までしかチェックできない
        if let remainingCount, selectedCount >= remainingCount {
            return .limitReached
        }
        return .changed(.init(selectedTitles: selectedTitles.union([candidate.title])))
    }

    /// 取り込む候補（チェックしていて、まだ登録していないもの）
    func importTargets(from candidates: [FrequentHouseworkImportCandidate]) -> [FrequentHouseworkImportCandidate] {
        candidates.filter { !$0.isAlreadyRegistered && selectedTitles.contains($0.title) }
    }

}

extension FrequentHouseworkImportSelection {

    /// チェックを切り替えた結果
    enum ToggleResult: Equatable {

        /// 切り替えた後の選択状態
        case changed(FrequentHouseworkImportSelection)
        /// 無料プランの上限に達していて、これ以上チェックできない
        case limitReached
        /// すでに登録済みで、チェックを外せない
        case unavailable

    }

}
