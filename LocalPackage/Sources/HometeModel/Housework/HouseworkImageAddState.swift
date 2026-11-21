//
//  HouseworkImageAddState.swift
//  LocalPackage
//

/// 画像の欄に出す、追加ボタンの状態
public enum HouseworkImageAddState: Equatable, Sendable {

    /// 追加できる
    case available(remainingCount: Int)
    /// 添えられる枚数に達している
    case limitReached
    /// 無料プラン。追加ボタンは出し、押すとプレミアムプランの案内を出す（使えることが分かるようにする）
    case premiumRequired
    /// 追加ボタンを出さない（完了・「やらない」の家事、くり返す家事として登録する入力中の家事）
    case hidden

}

public extension HouseworkImageAddState {

    /// - Parameters:
    ///   - canAdd: 家事として画像を添えられる状態か（未完了の家事・その日の家事として登録する入力中の家事）
    ///   - policy: 操作している本人のプラン
    ///   - currentCount: 添えてある画像の枚数
    static func make(canAdd: Bool, policy: HouseworkImagePolicy, currentCount: Int) -> Self {
        guard canAdd else { return .hidden }

        switch policy {
        case .free:
            return .premiumRequired

        case .premium:
            let remainingCount = policy.addableCount(currentCount: currentCount)
            return remainingCount > 0 ? .available(remainingCount: remainingCount) : .limitReached
        }
    }

}
