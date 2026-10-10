//
//  LoadErrorView.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

/// Firestoreの監視・取得に失敗した画面で表示する、エラー内容とリトライ導線
public struct LoadErrorView: View {

    let error: DomainError
    let onTapRetry: () -> Void

    public init(error: DomainError, onTapRetry: @escaping () -> Void) {
        self.error = error
        self.onTapRetry = onTapRetry
    }

    public var body: some View {
        VStack(spacing: .space24) {
            VStack(spacing: .space16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.iconDecorative)
                Text("うまく読み込めませんでした", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                onTapRetry()
            } label: {
                Text("もう一度試す", bundle: #bundle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
        }
        .padding(.horizontal, .space16)
    }

}

private extension LoadErrorView {

    var message: LocalizedStringResource {
        switch error {
        case .noNetwork:
            .localized("通信状態をご確認のうえ、もう一度お試しください。")

        case .failAuth:
            .localized("認証に失敗しました。再度サインインをお試しください。")

        case .accountNotFound:
            .localized("アカウント情報を確認できませんでした。アプリを再起動して、もう一度お試しください。")

        case .other:
            .localized("時間をおいて、もう一度お試しください。")
        }
    }

}

#Preview("LoadErrorView_通信エラー") {
    LoadErrorView(error: .noNetwork, onTapRetry: {})
}

#Preview("LoadErrorView_不明なエラー") {
    LoadErrorView(error: .other, onTapRetry: {})
}
