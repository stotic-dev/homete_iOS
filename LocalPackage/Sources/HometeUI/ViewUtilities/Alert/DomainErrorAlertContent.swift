//
//  DomainErrorAlertContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/11.
//

#if canImport(UIKit)
import HometeDomain
import SwiftUI

public struct DomainErrorAlertContent: Sendable {

    public var isPresenting = false
    public let error: DomainError?

    public init(isPresenting: Bool = false, error: DomainError?) {
        self.isPresenting = isPresenting
        self.error = error
    }

    public var hasError: Bool { error != nil }

    public var errorMessage: LocalizedStringKey? {

        switch error {

        case .failAuth:
            return "認証に失敗しました。再度サインインをお試しください。"

        case .noNetwork:
            return "通信に失敗しました"

        case .other:
            return "不明のエラーが発生しました"

        default:
            return nil
        }
    }

    public static let initial = DomainErrorAlertContent(isPresenting: false, error: nil)
}

public extension DomainErrorAlertContent {

    init(error: any Error) {

        isPresenting = true
        self.error = .make(error)
    }
}
#endif
