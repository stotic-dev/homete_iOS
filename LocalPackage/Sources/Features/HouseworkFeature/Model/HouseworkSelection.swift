//
//  HouseworkSelection.swift
//  homete
//

import HometeDomain

/// 家事リストの複数選択状態
///
/// 「一緒に選択できるか」「一括操作バーに何を並べるか」「アクションの適用対象はどれか」といった
/// 選択に関する判定はすべてここに集約する。判定がViewごとに散っていると、選択制限とバーの表示が
/// 食い違ったときに原因を追いにくく、テストもViewを介さないと書けなくなるため。
///
/// - Note: 選択IDの保持自体はView側の`@State`に残る。`List(selection:)`が
///   `Binding<Set<String>>`を要求するため、この値型を状態として持たせることはできない。
///   Viewは`body`評価のたびにこの値型を組み立てて問い合わせる。
struct HouseworkSelection: Equatable {

    /// 選択対象となるリストの全項目
    let items: [HouseworkBoardItem]
    /// リストが表示している家事のステータス（タブ1つにつき1ステータス）
    let state: HouseworkState
    /// 選択中の家事のID
    let selectedIDs: Set<String>
    /// ログイン中のユーザーID
    let ownUserId: String

    /// 選択中の家事
    var selectedItems: [HouseworkBoardItem] {
        items.filter { selectedIDs.contains($0.id) }
    }

    /// 何も選択されていないかどうか
    var isEmpty: Bool {
        selectedItems.isEmpty
    }

    /// 一括操作バーに並べるアクション
    ///
    /// 同じステータスでも実行者によって行えるアクションは変わる（承認待ちでも自分が承認依頼を出した
    /// 家事は差し戻ししか行えない）。ボタンをタブのステータスから決め打ちすると、選択内容によっては
    /// 実行できないボタンだけが非活性で並ぶため、選択中の家事から実際に行えるアクションを集める。
    /// まだ何も選択されていないうちは、タブのステータスから決まる既定のボタンを返す。
    var availableActions: [HouseworkQuickAction] {
        guard !isEmpty else {
            return HouseworkQuickAction.actions(for: state)
        }

        let available = Set(selectedItems.flatMap(actions(for:)))
        return HouseworkQuickAction.allCases.filter(available.contains)
    }

    /// すでに選択されている家事と一緒に選択できるかどうか
    ///
    /// 対応可能アクションが異なる家事を混ぜて選択できてしまうと、一括操作が選択したうちの一部の
    /// 家事にしか適用されず、何が実行されたのか分からなくなる。行えるアクションの組み合わせが
    /// 一致する家事だけを同時に選択できるようにする。
    func isSelectable(_ item: HouseworkBoardItem) -> Bool {
        guard let selected = selectedItems.first else { return true }

        return actions(for: item) == actions(for: selected)
    }

    /// 選択中の家事のうち、そのアクションを実際に適用できる対象
    ///
    /// `isSelectable(_:)`によって対応可能アクションが揃った家事しか同時に選択できないため通常は
    /// 選択中の全件が対象になる。選択したあとにリスナー経由でリストが更新され、状態が変わった家事が
    /// 選択に残るケースの取りこぼしを防ぐために絞り込む。
    func targets(for action: HouseworkQuickAction) -> [HouseworkBoardItem] {
        selectedItems.filter { actions(for: $0).contains(action) }
    }

}

private extension HouseworkSelection {

    func actions(for item: HouseworkBoardItem) -> [HouseworkQuickAction] {
        HouseworkQuickAction.actions(for: item, ownUserId: ownUserId)
    }

}
