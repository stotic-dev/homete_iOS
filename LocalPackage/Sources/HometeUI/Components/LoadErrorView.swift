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
                    .foregroundStyle(.primary3)
                Text("うまく読み込めませんでした")
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
                    .multilineTextAlignment(.center)
            }
            Button {
                onTapRetry()
            } label: {
                Text("もう一度試す")
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
        .padding(.horizontal, .space16)
    }

}

private extension LoadErrorView {

    var message: String {
        switch error {
        case .noNetwork:
            "通信状態をご確認のうえ、もう一度お試しください。"

        case .failAuth:
            "認証に失敗しました。再度サインインをお試しください。"

        case .other:
            "時間をおいて、もう一度お試しください。"
        }
    }

}

#Preview("LoadErrorView_通信エラー") {
    LoadErrorView(error: .noNetwork, onTapRetry: {})
}

#Preview("LoadErrorView_不明なエラー") {
    LoadErrorView(error: .other, onTapRetry: {})
}
