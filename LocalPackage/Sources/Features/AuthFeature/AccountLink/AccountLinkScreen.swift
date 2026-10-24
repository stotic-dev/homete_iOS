//
//  AccountLinkScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 匿名のアカウントをAppleアカウントと連携する画面
///
/// オンボーディング・全画面（匿名のままグループに参加している）・やることリスト・設定・Paywallの前で共通に使う。
/// Appleアカウントがすでに別のアカウントで使われていたら、そのアカウントへ切り替えるかを確認する。
public struct AccountLinkScreen: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @CommonError var commonErrorContent
    @LoadingState var loadingState

    @State var existingAccountCredential: ExistingAccountCredential?

    let entry: AccountLinkEntry
    let onClose: (() -> Void)?
    let onCompleted: () -> Void

    /// - Parameters:
    ///   - entry: 連携を求めた場所
    ///   - onClose: 連携せずに閉じたとき。`nil`なら閉じるボタンを出さない（連携を必須にする）
    ///   - onCompleted: 連携した、または既存のアカウントへ切り替えたとき
    public init(
        entry: AccountLinkEntry,
        onClose: (() -> Void)? = nil,
        onCompleted: @escaping () -> Void = {}
    ) {
        self.entry = entry
        self.onClose = onClose
        self.onCompleted = onCompleted
    }

    public var body: some View {
        NavigationStack {
            AccountLinkView(
                entry: entry,
                isClosable: onClose != nil,
                onSignInWithApple: { result in
                    await onSignInWithApple(result)
                },
                onTapClose: {
                    tappedClose()
                }
            )
        }
        .alert(
            .localized("このAppleアカウントは、すでに\(Constants.appName)で使われています"),
            isPresented: isPresentedExistingAccountAlert,
            presenting: existingAccountCredential
        ) { credential in
            Button(.localized("ログインする"), role: .destructive) {
                loadingState.task {
                    await tappedSwitchToExistingAccount(credential)
                }
            }
            Button(.localized("キャンセル"), role: .cancel) {
                tappedCancelSwitchingAccount()
            }
        } message: { _ in
            Text(
                "そのアカウントでログインしますか？ここまでに登録したニックネームとパートナーは引き継がれず、削除されます。",
                bundle: #bundle
            )
        }
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonErrorContent)
        .trackScreenView(.accountLink)
    }

}

// MARK: - プレゼンテーションロジック

private extension AccountLinkScreen {

    var isPresentedExistingAccountAlert: Binding<Bool> {
        .init(
            get: { existingAccountCredential != nil },
            set: { isPresented in
                if !isPresented {
                    existingAccountCredential = nil
                }
            }
        )
    }

    func onSignInWithApple(_ result: Result<SignInWithAppleResult, any Error>) async {
        switch result {
        case let .success(signInResult):
            loadingState.isLoading = true
            defer { loadingState.isLoading = false }

            do {
                try await accountAuthStore.linkWithApple(signInResult)
                log(.success)
                onCompleted()
            } catch let AccountLinkError.credentialAlreadyInUse(credential) {
                existingAccountCredential = credential
            } catch {
                log(.failure)
                commonErrorContent = .init(error: error)
            }

        case let .failure(error):
            log(.failure)
            commonErrorContent = .init(error: error)
        }
    }

    func tappedSwitchToExistingAccount(_ credential: ExistingAccountCredential) async {
        do {
            try await accountAuthStore.switchToExistingAccount(credential)
            log(.conflictSwitched)
            onCompleted()
        } catch {
            log(.failure)
            commonErrorContent = .init(error: error)
        }
    }

    func tappedCancelSwitchingAccount() {
        log(.cancel)
    }

    func tappedClose() {
        log(.cancel)
        onClose?()
    }

    func log(_ result: AccountLinkAnalyticsResult) {
        analyticsClient.log(.accountLink(.init(entry: entry, result: result)))
    }

}
