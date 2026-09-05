//
//  DashboardLoadErrorView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ダッシュボードの初回ロードに失敗した際に表示する、エラー内容とリトライ導線
struct DashboardLoadErrorView: View {

    let error: DomainError
    let onTapRetry: () -> Void

    var body: some View {
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

private extension DashboardLoadErrorView {

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

#Preview("DashboardLoadErrorView_通信エラー") {
    DashboardLoadErrorView(error: .noNetwork, onTapRetry: {})
}

#Preview("DashboardLoadErrorView_不明なエラー") {
    DashboardLoadErrorView(error: .other, onTapRetry: {})
}
