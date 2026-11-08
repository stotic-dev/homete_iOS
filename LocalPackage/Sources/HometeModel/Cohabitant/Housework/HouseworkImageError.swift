//
//  HouseworkImageError.swift
//  LocalPackage
//

/// 家事の画像の追加・削除で起きるエラー
public enum HouseworkImageError: Error, Equatable, Sendable {

    /// 家事が完了・「やらない」になっていて、画像を追加できない
    case notEditable
    /// 無料プランでは画像を追加できない
    /// - Note: 追加ボタンからペイウォールへ誘導しているため、通常の操作では起きない
    case premiumRequired
    /// 1つの家事に添えられる枚数を超える
    case limitExceeded
    /// 自分が追加した画像ではなく、プレミアムプランでもないため消せない
    case notDeletable
    /// 画像として読み込めない（選んだファイルが壊れている・取得した画像が読めない）
    case unreadable

}
