//
//  PartnerRegistrationScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// オンボーディングでパートナーを登録する画面
///
/// 招待リンクから来た人（未処理の招待トークンがある人）には、選択肢を出さずに参加確認を出す。
/// 参加確認・P2Pでの登録は別のFeatureの画面なので、`RouteResolver`経由で出す。
struct PartnerRegistrationScreen: View {

    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.appDependencies.cohabitantInvitationClient) var cohabitantInvitationClient
    @Environment(\.appDependencies.pasteboardClient) var pasteboardClient
    @Environment(AccountStore.self) var accountStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(SentInvitationStore.self) var sentInvitationStore
    @LoadingState var loadingState
    @CommonError var errorContent

    @State var pasteboardInvitationStore: PasteboardInvitationStore?
    @State var sharingInvitation: CohabitantInvitation?
    /// 共有シートを閉じたが、共有を完了したと分からなかった招待
    /// - Note: 共有先のアプリによっては、送っても完了と伝えてこない。送った人が自分で次へ進めるよう、閉じた後も持っておく
    @State var unconfirmedInvitation: CohabitantInvitation?
    /// 招待リンクの共有を完了したか
    /// - Note: 送った直後に画面が切り替わると何が起きたか分からないため、自動では次へ進めず、送ったことを伝えてボタンで進めてもらう
    @State var hasSharedInvitation = false
    @State var isShowCohabitantRegistration = false
    /// P2Pでの登録画面を開いたときに送ってあった招待。登録画面の中から招待を送ったかを見分けるために使う
    @State var sentInvitationTokenBeforeRegistration: String?

    let account: Account
    /// パートナー登録を終えたとき
    /// - Parameter hasRegisteredPartner: 招待の共有・P2Pでの登録・招待への参加のどれかを終えたか。「あとで」なら`false`
    let onNext: (_ hasRegisteredPartner: Bool) -> Void

    var body: some View {
        PartnerRegistrationView(
            isInvitationAvailable: CohabitantInvitationLink.isAvailable,
            isInvitationNotFound: pasteboardInvitationStore?.state == .notFound,
            invitationShareState: invitationShareState,
            onTapInvite: {
                loadingState.task {
                    await tappedInvite()
                }
            },
            onTapSentInvitation: { tappedSentInvitation() },
            onTapNextAfterShare: { tappedNextAfterShare() },
            onTapNearby: { tappedNearby() },
            onTapInvited: {
                Task {
                    await tappedInvited()
                }
            },
            onTapLater: { tappedLater() }
        )
        .shareSheet(
            item: $sharingInvitation,
            text: CohabitantInvitation.shareMessage,
            url: \.url,
            onFinish: { invitation, isCompleted in
                finishedShareSheet(invitation, isCompleted: isCompleted)
            }
        )
        .fullScreenCoverOnIOS(
            isPresented: $isShowCohabitantRegistration,
            onDismiss: { dismissedCohabitantRegistration() },
            content: { router.resolve(.cohabitantRegistration) }
        )
        // 招待リンクから来た人と、この画面にいる間にリンクを開いた人には、選択肢の代わりに参加確認を出す
        .fullScreenCoverOnIOS(
            isPresented: isPresentingCohabitantJoin,
            onDismiss: { dismissedCohabitantJoin() },
            content: {
                if let token = pendingInvitationStore.pendingToken {
                    router.resolve(.cohabitantJoin(token: token))
                }
            }
        )
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $errorContent)
        .trackScreenView(.onboardingPartnerRegistration)
    }

}

// MARK: プレゼンテーションロジック

private extension PartnerRegistrationScreen {

    /// 参加確認を出すかどうか
    /// - Note: 閉じたら未処理のトークンを破棄して、同じ招待で出し直さないようにする
    var isPresentingCohabitantJoin: Binding<Bool> {
        .init(
            get: { pendingInvitationStore.pendingToken != nil },
            set: { isPresenting in
                if !isPresenting {
                    pendingInvitationStore.clear()
                }
            }
        )
    }

    var invitationShareState: PartnerInvitationShareState {
        if unconfirmedInvitation != nil {
            .unconfirmed
        } else if hasSharedInvitation {
            .shared
        } else {
            .notShared
        }
    }

    var hasJoinedCohabitant: Bool {
        accountStore.account?.cohabitantId != nil
    }

    func tappedInvite() async {
        analyticsClient.log(.onboarding(.partnerRegistrationSelected(.invite)))
        do {
            // 発行時点ではグループは作られない。相手が参加した時点でサーバー側がグループを作る
            sharingInvitation = try await cohabitantInvitationClient.issue()
            analyticsClient.log(.cohabitantInvitation(.issued(screen: .onboarding, isSuccess: true)))
        } catch {
            errorContent = .init(error: error)
            analyticsClient.log(.cohabitantInvitation(.issued(screen: .onboarding, isSuccess: false)))
        }
    }

    /// 共有を完了したら、送ったことを伝えて「次へ」を出す。相手の参加は待たない。キャンセルしたら送れたかを尋ねる
    func finishedShareSheet(_ invitation: CohabitantInvitation, isCompleted: Bool) {
        guard isCompleted else {
            unconfirmedInvitation = invitation
            hasSharedInvitation = false
            return
        }
        saveSharedInvitation(invitation)
    }

    /// 共有を完了したと分からなかった招待を、送ったと言われたら送ったものとして次へ進む
    func tappedSentInvitation() {
        guard let unconfirmedInvitation else { return }
        saveSharedInvitation(unconfirmedInvitation)
        onNext(true)
    }

    func tappedNextAfterShare() {
        onNext(true)
    }

    func saveSharedInvitation(_ invitation: CohabitantInvitation) {
        unconfirmedInvitation = nil
        hasSharedInvitation = true
        Task {
            await sentInvitationStore.save(invitation, accountId: account.id)
        }
    }

    func tappedNearby() {
        analyticsClient.log(.onboarding(.partnerRegistrationSelected(.nearby)))
        sentInvitationTokenBeforeRegistration = sentInvitationStore.sentInvitation?.token
        isShowCohabitantRegistration = true
    }

    /// 登録を終えて閉じたら次へ進む。途中で閉じたら選択肢に戻る
    /// - Note: 登録画面の中の「リンクで招待」から招待を送った場合も、招待を送ったものとして次へ進む
    func dismissedCohabitantRegistration() {
        let hasSentInvitation = sentInvitationStore.sentInvitation?.token != sentInvitationTokenBeforeRegistration
        guard hasJoinedCohabitant || hasSentInvitation else { return }
        onNext(true)
    }

    /// クリップボードの招待リンクを読み取る。見つかれば参加確認が出る
    func tappedInvited() async {
        analyticsClient.log(.onboarding(.partnerRegistrationSelected(.invited)))
        if pasteboardInvitationStore == nil {
            pasteboardInvitationStore = .init(
                pasteboardClient: pasteboardClient,
                analyticsClient: analyticsClient,
                pendingInvitationStore: pendingInvitationStore
            )
        }
        await pasteboardInvitationStore?.readInvitation()
    }

    /// 参加したら次へ進む。断ったら選択肢に戻る
    func dismissedCohabitantJoin() {
        guard hasJoinedCohabitant else { return }
        onNext(true)
    }

    func tappedLater() {
        analyticsClient.log(.onboarding(.partnerRegistrationSelected(.later)))
        onNext(false)
    }

}
