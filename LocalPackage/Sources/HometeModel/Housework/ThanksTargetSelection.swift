//
//  ThanksTargetSelection.swift
//  LocalPackage
//


/// ありがとうを伝えられる家事の一覧での複数選択状態
///
/// この一覧で一括で行えるのはありがとうを送ることだけなので、家事ボードの`HouseworkSelection`のように
/// アクションの組み合わせで選択を制限せず、まだありがとうを送っていない家事だけを選べるようにする。
///
/// - Note: 選択IDの保持は`List(selection:)`に渡すため、View側の`@State`に残す。
public struct ThanksTargetSelection: Equatable, Sendable {

    /// 一覧に並んでいる家事
    public let items: [HouseworkBoardItem]
    /// 選択中の家事のID
    public let selectedIDs: Set<String>
    /// ログイン中のユーザーID
    public let ownUserId: String

    public init(
        items: [HouseworkBoardItem],
        selectedIDs: Set<String>,
        ownUserId: String
    ) {
        self.items = items
        self.selectedIDs = selectedIDs
        self.ownUserId = ownUserId
    }

    /// まだありがとうを送っていない家事があり、選択モードに入る意味があるかどうか
    public var hasSelectableItems: Bool {
        items.contains(where: isSelectable)
    }

    /// 一括でありがとうを送る対象
    ///
    /// 選択したあとに、ほかの端末から送ったありがとうがリスナー経由で届き、送信済みになった家事が
    /// 選択に残るケースを取りこぼさないよう、まだ送っていない家事に絞り込む。
    public var targets: [HouseworkBoardItem] {
        items.filter { selectedIDs.contains($0.id) && isSelectable($0) }
    }

    /// 選択できる家事かどうか。送信済みの家事に、もう一度ありがとうは送れない
    public func isSelectable(_ item: HouseworkBoardItem) -> Bool {
        HouseworkThanksStatus.make(item: item, ownUserId: ownUserId) == .notSent
    }

}
