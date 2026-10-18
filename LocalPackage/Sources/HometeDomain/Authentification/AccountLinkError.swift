//
//  AccountLinkError.swift
//  LocalPackage
//

/// 匿名のアカウントをAppleアカウントと連携できなかった理由
public enum AccountLinkError: Error, Sendable {

    /// Appleアカウントが、すでに別のhometeのアカウントで使われている
    case credentialAlreadyInUse(ExistingAccountCredential)

}

/// すでに別のアカウントで使われていたAppleアカウントの認証情報
///
/// Appleの認証情報は1回しか使えないため、連携に失敗した時点で受け取ったものを使って、そのアカウントへログインし直す。
/// - Note: 中身はFirebaseの認証情報で、扱うのはInfra層だけ。Domainからは中身を見ずに受け渡す
public struct ExistingAccountCredential: Sendable {

    public let rawValue: any Sendable

    public init(rawValue: any Sendable) {
        self.rawValue = rawValue
    }

}
