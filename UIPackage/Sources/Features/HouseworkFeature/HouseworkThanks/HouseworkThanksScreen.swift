//
//  HouseworkThanksScreen.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/23.
//

import HometeDomainUI
import HometeDomain
import HometeUI
import HouseworkFeatureUI
import SwiftUI

/// 完了した家事にありがとうを伝えるハーフモーダル
public struct HouseworkThanksScreen: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.loginContext.account) var account
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @CommonError var commonError
    @LoadingState var loadingState

    let item: HouseworkBoardItem
    /// すでに送ったありがとう。あればコメントの編集として開く
    let sentThanks: HouseworkThanks?
    /// どの画面から開いたか。Analyticsで、ありがとうの経由を区別するために使う
    let step: HouseworkAnalyticsStep
    /// 初めてありがとうを伝えられた。閉じた後の画面で演出を出すために、開いた側へ伝える
    let onSentFirstThanks: () -> Void

    init(
        item: HouseworkBoardItem,
        sentThanks: HouseworkThanks? = nil,
        step: HouseworkAnalyticsStep = .thanks,
        onSentFirstThanks: @escaping () -> Void
    ) {
        self.item = item
        self.sentThanks = sentThanks
        self.step = step
        self.onSentFirstThanks = onSentFirstThanks
    }

    public var body: some View {
        NavigationStack {
            HouseworkThanksView(sentThanks: sentThanks) { message in
                loadingState.task {
                    await tappedSendThanksButton(message: message)
                }
            }
        }
        // 中身の高さに合わせると、キーボードを出したときにシートが持ち上がりすぎてハーフモーダルに
        // ならないため、高さを決め打ちする
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkThanks)
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkThanksScreen {

    /// ハーフモーダルの高さ。3行の入力欄と文字数が収まる高さ
    var sheetHeight: CGFloat {
        250
    }

    func tappedSendThanksButton(message: String) async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let isFirstThanks = try await houseworkListStore.sendThanks(
                target: item.originalItem,
                sender: account,
                comment: message,
                now: now,
                cohabitantId: cohabitantId,
                step: step
            )
            if isFirstThanks {
                onSentFirstThanks()
            }
            dismiss()
        } catch {
            commonError = .init(error: error)
        }
    }

}
