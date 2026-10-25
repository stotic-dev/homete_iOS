//
//  InquiryCreationStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// 問い合わせの作成を扱うStore
@MainActor
@Observable
public final class InquiryCreationStore {

    public var category: InquiryCategory?
    public var submission = InquirySubmission()

    // MARK: Dependencies

    private let inquiryClient: InquiryClient
    private let makeRequestId: @Sendable () -> String

    public init(
        inquiryClient: InquiryClient = .previewValue,
        makeRequestId: @Sendable @escaping () -> String = { UUID().uuidString }
    ) {
        self.inquiryClient = inquiryClient
        self.makeRequestId = makeRequestId
    }

    /// 送信ボタンを押せるか
    public var canSubmit: Bool {
        category != nil && submission.canSubmit
    }

    /// 入力途中の内容があるか。閉じる前に確かめるのに使う
    public var hasInput: Bool {
        category != nil || !submission.body.isEmpty
    }

    /// 問い合わせを作る
    /// - Returns: 作った問い合わせ。送れなかった場合は`nil`で、入力は残したまま`submission.failure`に理由が入る
    public func submit() async -> Inquiry? {
        guard let category,
              let requestId = submission.begin(makeRequestId: makeRequestId) else { return nil }

        do {
            let result = try await inquiryClient.create(
                .init(requestId: requestId, category: category, body: submission.body)
            )
            submission.succeed()
            return result.inquiry
        } catch {
            submission.fail(error)
            return nil
        }
    }

}
