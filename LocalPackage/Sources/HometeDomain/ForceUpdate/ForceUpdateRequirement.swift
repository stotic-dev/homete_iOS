//
//  ForceUpdateRequirement.swift
//  LocalPackage
//

import Foundation

/// 強制アップデートが必要な状態
public struct ForceUpdateRequirement: Equatable, Sendable {

    /// Remote Configで配信された案内文言。未設定なら`nil`
    public let message: String?

    public init(message: String?) {
        self.message = message
    }

}

public extension ForceUpdateRequirement {

    /// 現在のバージョンが最低バージョンを下回っていれば、強制アップデートが必要な状態を返す
    /// - Returns: アップデートが不要なら`nil`。どちらかのバージョンが空・不正な値の場合も`nil`にする
    /// - Note: 誤設定でユーザー全員を締め出さないよう、判定できないときはブロックしない側に倒す
    static func make(
        currentVersion: String,
        minimumRequiredVersion: String,
        message: String
    ) -> ForceUpdateRequirement? {
        guard let current = AppVersion(currentVersion),
              let minimum = AppVersion(minimumRequiredVersion),
              current < minimum else { return nil }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return .init(message: trimmedMessage.isEmpty ? nil : trimmedMessage)
    }

}
