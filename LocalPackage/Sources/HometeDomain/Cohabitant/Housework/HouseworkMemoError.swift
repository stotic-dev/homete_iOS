//
//  HouseworkMemoError.swift
//  LocalPackage
//

/// 家事メモの保存で起きるエラー
public enum HouseworkMemoError: Error, Equatable, Sendable {

    /// 家事が完了・「やらない」になっていて、メモを編集できない
    case notEditable
    /// 文字数・項目数がプランの上限を超えている
    /// - Note: 編集シートで保存できないようにしているため、通常の操作では起きない。
    ///         Firestoreルールの安全上限に当たる前に、クライアントで弾くための保険
    case limitExceeded

}
