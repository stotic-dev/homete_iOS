//
//  LoginMethod.swift
//  LocalPackage
//

/// `login`イベントで送る、サインインの方法
public enum LoginMethod: String, Equatable, Sendable {

    /// Sign in with Apple
    case apple
    /// 匿名認証（説明画面の「はじめる」）
    case anonymous

}
