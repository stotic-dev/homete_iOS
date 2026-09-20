//
//  PasteboardInvitationStore.swift
//  LocalPackage
//

import Observation

/// クリップボードにコピーされた招待リンクを拾う（ディファードディープリンク）ためのStore
///
/// 着地ページの「初めての方はこちら」でコピーされた招待URLを、インストール後のアプリが受け取る。
/// グループ未所属のダッシュボードが表示されている間、フォアグラウンド復帰のたびに
/// クリップボードの存在確認だけを行い、URLらしきものがあれば案内を出す。
/// 内容の読み取りはシステムのペースト通知が出るため、ユーザーが案内をタップしたときだけ行う。
@MainActor
@Observable
public final class PasteboardInvitationStore {

    public enum State: Equatable, Sendable {

        /// 案内を出さない
        case idle
        /// 「招待リンクを確認する」の案内を出す
        case suggesting
        /// 読み取ったが招待リンクではなかった
        case notFound

    }

    public private(set) var state: State = .idle

    /// 案内・読み取りを済ませたクリップボードの世代
    /// - Note: 同じ内容で再度案内しないために使う。読み取って招待リンクでなかった内容も対象
    private var handledChangeCount: Int?

    // MARK: Dependencies

    private let pasteboardClient: PasteboardClient
    private let analyticsClient: AnalyticsClient
    private let pendingInvitationStore: PendingInvitationStore

    public init(
        pasteboardClient: PasteboardClient = .previewValue,
        analyticsClient: AnalyticsClient = .previewValue,
        pendingInvitationStore: PendingInvitationStore = .init()
    ) {
        self.pasteboardClient = pasteboardClient
        self.analyticsClient = analyticsClient
        self.pendingInvitationStore = pendingInvitationStore
    }

    /// クリップボードにURLらしきものがあれば案内を出す
    /// - Note: 表示時とフォアグラウンド復帰時に呼ぶ。内容は読まないためペースト通知は出ない
    public func checkIfNeeded() async {
        let detection = await pasteboardClient.detectProbableWebURL()

        // 読み取り済みの内容には、案内も「見つかりませんでした」の表示もそのまま（再度案内しない）
        guard detection.changeCount != handledChangeCount else { return }

        guard detection.hasProbableWebURL else {
            // クリップボードが別の内容に変わって（消えて）いれば、前回の表示は引っ込める
            state = .idle
            return
        }

        guard state != .suggesting else { return }
        state = .suggesting
        analyticsClient.log(.cohabitantInvitation(.pasteboardChecked(isSuggested: true)))
    }

    /// クリップボードを読み取り、招待リンクなら参加画面へ渡す
    /// - Note: 「招待リンクを確認する」のタップ時に呼ぶ。ペースト通知が出る
    public func readInvitation() async {
        // 読み取り時点の世代を控えておき、同じ内容で再度案内しないようにする
        handledChangeCount = await pasteboardClient.detectProbableWebURL().changeCount

        guard let url = await pasteboardClient.readURL(),
              let token = CohabitantInvitationLink.token(from: url) else {
            state = .notFound
            analyticsClient.log(.cohabitantInvitation(.pasteboardChecked(isSuggested: false)))
            return
        }

        state = .idle
        pendingInvitationStore.store(token)
        analyticsClient.log(.cohabitantInvitation(.linkOpened(source: .pasteboard)))
    }

}
