//
//  PasteboardClient.swift
//  LocalPackage
//

import Foundation

/// クリップボードにコピーされた招待リンクを拾うためのClient
///
/// 着地ページの「初めての方はこちら」でコピーされた招待URLを、インストール後のアプリが受け取るために使う。
/// クリップボードの内容を読むとシステムのペースト通知が出るため、存在確認（`detectProbableWebURL`）と
/// 読み取り（`readURL`）を分け、読み取りはユーザー操作起点でのみ行う。
public struct PasteboardClient: Sendable {

    /// クリップボードにURLらしきものがあるかを、内容を読まずに調べる
    public let detectProbableWebURL: @Sendable () async -> PasteboardDetection
    /// クリップボードの内容をURLとして読み取る
    /// - Note: システムのペースト通知が出るため、ユーザー操作起点でのみ呼ぶ
    public let readURL: @Sendable () async -> URL?

    public init(
        detectProbableWebURL: @Sendable @escaping () async -> PasteboardDetection = {
            .init(hasProbableWebURL: false, changeCount: 0)
        },
        readURL: @Sendable @escaping () async -> URL? = { nil }
    ) {
        self.detectProbableWebURL = detectProbableWebURL
        self.readURL = readURL
    }

}

public extension PasteboardClient {

    static let previewValue: PasteboardClient = .init()

}

/// クリップボードの存在確認の結果
public struct PasteboardDetection: Equatable, Sendable {

    /// URLらしきものがあるかどうか
    public let hasProbableWebURL: Bool
    /// クリップボードの世代
    /// - Note: 内容が変わるたびに増える。同じ内容を二度案内しないための識別に使う
    public let changeCount: Int

    public init(hasProbableWebURL: Bool, changeCount: Int) {
        self.hasProbableWebURL = hasProbableWebURL
        self.changeCount = changeCount
    }

}
