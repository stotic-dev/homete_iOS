//
//  HouseworkMemoError.swift
//  LocalPackage
//

/// 家事メモの保存で起きるエラー
public enum HouseworkMemoError: Error, Equatable, Sendable {

    /// 家事が完了・「やらない」になっていて、メモを編集できない
    case notEditable

}
