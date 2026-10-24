//
//  InquiryDetailStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// 問い合わせの詳細（メッセージ履歴）と、追加のメッセージの送信を扱うStore
@MainActor
@Observable
public final class InquiryDetailStore {

    public private(set) var state = InquiryDetailState()
    public var submission = InquirySubmission()

    private let inquiryId: String

    // MARK: Dependencies

    private let inquiryClient: InquiryClient
    private let makeRequestId: @Sendable () -> String
    /// 送信・既読で問い合わせが変わったときに呼ぶ。一覧へ反映するのに使う
    private let onUpdate: @MainActor (Inquiry) -> Void

    public init(
        inquiryId: String,
        inquiryClient: InquiryClient = .previewValue,
        makeRequestId: @Sendable @escaping () -> String = { UUID().uuidString },
        onUpdate: @MainActor @escaping (Inquiry) -> Void = { _ in }
    ) {
        self.inquiryId = inquiryId
        self.inquiryClient = inquiryClient
        self.makeRequestId = makeRequestId
        self.onUpdate = onUpdate
    }

    /// 最新のメッセージから取り直し、運営の返信が未読なら既読にする
    /// - Note: 取り直すと、さかのぼって読み込んだ古いメッセージは捨てて最新のページだけにする。
    ///         取得中にもう一度呼ばれた場合は何もしない。失敗しても取得済みの内容は残す
    public func load() async {
        guard !state.isLoading else { return }

        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let page = try await inquiryClient.fetch(inquiryId, nil)
            state.inquiry = page.inquiry
            // APIは新しい順に返すが、画面では古い順に上から並べる
            state.messages = page.messages.reversed()
            state.olderCursor = page.nextCursor
            state.loadFailure = nil
        } catch {
            // 画面を閉じて取得がキャンセルされた場合は失敗として扱わない
            guard !Task.isCancelled else { return }
            state.loadFailure = .init(error)
            return
        }

        await markReadIfNeeded()
    }

    /// 表示中より古いメッセージを読み込んで先頭に足す
    public func loadOlder() async {
        guard let cursor = state.olderCursor, !state.isLoadingOlder, !state.isLoading else { return }

        state.isLoadingOlder = true
        defer { state.isLoadingOlder = false }

        do {
            let page = try await inquiryClient.fetch(inquiryId, cursor)
            let loadedIds = Set(state.messages.map(\.id))
            state.messages.insert(contentsOf: page.messages.reversed().filter { !loadedIds.contains($0.id) }, at: 0)
            state.olderCursor = page.nextCursor
        } catch {
            return
        }
    }

    /// 入力中の本文をメッセージとして送る
    /// - Note: 失敗した場合は入力を残し、`submission.failure`に理由が入る
    public func submit() async {
        guard let requestId = submission.begin(makeRequestId: makeRequestId) else { return }

        do {
            let result = try await inquiryClient.sendMessage(inquiryId, requestId, submission.body)
            submission.succeed()
            state.inquiry = result.inquiry
            // 送っている間に取り直して、すでに表示している場合がある
            if !state.messages.contains(where: { $0.id == result.message.id }) {
                state.messages.append(result.message)
            }
            onUpdate(result.inquiry)
        } catch {
            submission.fail(error)
        }
    }

}

private extension InquiryDetailStore {

    /// 表示した最新のメッセージまでを既読にする
    /// - Note: 失敗しても次に開いたときにまた既読にするため、エラーは出さない
    func markReadIfNeeded() async {
        guard let inquiry = state.inquiry,
              inquiry.hasUnreadReply,
              let latestMessage = state.messages.last else { return }

        do {
            let updatedInquiry = try await inquiryClient.markRead(inquiryId, latestMessage.id)
            state.inquiry = updatedInquiry
            onUpdate(updatedInquiry)
        } catch {
            return
        }
    }

}

/// 問い合わせの詳細の状態
public struct InquiryDetailState: Equatable, Sendable {

    /// 取得するまでは`nil`
    public var inquiry: Inquiry?
    /// 古い順
    public var messages: [InquiryMessage] = []
    /// さらに古いメッセージを取るときに渡す値。`nil`なら最も古いメッセージまで表示している
    public var olderCursor: String?
    public var isLoading = false
    public var isLoadingOlder = false
    /// 直近の取り直しに失敗した理由
    public var loadFailure: InquiryFailure?

    public init(
        inquiry: Inquiry? = nil,
        messages: [InquiryMessage] = [],
        olderCursor: String? = nil,
        isLoading: Bool = false,
        isLoadingOlder: Bool = false,
        loadFailure: InquiryFailure? = nil
    ) {
        self.inquiry = inquiry
        self.messages = messages
        self.olderCursor = olderCursor
        self.isLoading = isLoading
        self.isLoadingOlder = isLoadingOlder
        self.loadFailure = loadFailure
    }

    public var hasOlderMessages: Bool {
        olderCursor != nil
    }

}
