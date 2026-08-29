//
//  CohabitantJoinFailureView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 招待リンクからのグループ参加に失敗した理由を伝えるView
struct CohabitantJoinFailureView: View {

    let failure: CohabitantJoinFailure
    let onTapClose: () -> Void

    var body: some View {
        VStack(spacing: .space16) {
            Text(title)
                .font(with: .headLineL)
            Text(message)
                .font(with: .body)
            Spacer()
            Button {
                onTapClose()
            } label: {
                Text("閉じる")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
    }

}

private extension CohabitantJoinFailureView {

    var title: LocalizedStringKey {
        switch failure {
        case .invalidLink:
            "招待リンクが無効です"

        case .expired:
            "招待リンクの有効期限が切れています"

        case .alreadyJoined:
            "すでにグループに参加しています"

        case .unknown:
            "グループに参加できませんでした"
        }
    }

    var message: LocalizedStringKey {
        switch failure {
        case .invalidLink:
            "招待した方に、新しい招待リンクを送ってもらってください。"

        case .expired:
            "招待リンクは発行から24時間で期限が切れます。招待した方に、新しい招待リンクを送ってもらってください。"

        case .alreadyJoined:
            "別のグループに参加中のため、この招待では参加できません。"

        case .unknown:
            "お手数ですが、通信状況をご確認の上、再度お試しください。"
        }
    }

}

#Preview("CohabitantJoinFailureView_有効期限切れ") {
    CohabitantJoinFailureView(failure: .expired) {}
}

#Preview("CohabitantJoinFailureView_参加済み") {
    CohabitantJoinFailureView(failure: .alreadyJoined) {}
}
