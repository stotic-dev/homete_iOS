//
//  HouseworkDetailThanksCard.swift
//  homete
//

import HometeUI
import SwiftUI

/// 家事に届いたありがとう1件を、送った人とメッセージで表示する
struct HouseworkDetailThanksCard: View {

    let senderName: String
    let comment: String

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Label(senderName, systemImage: "hands.clap.fill")
                .font(with: .boldCaption)
                .foregroundStyle(.primary1)
            if !comment.isEmpty {
                Text(comment)
                    .font(with: .body)
                    .foregroundStyle(.onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCardStyle()
    }

}

#if DEBUG
#Preview("HouseworkDetailThanksCard_メッセージあり", traits: .sizeThatFitsLayout) {
    HouseworkDetailThanksCard(
        senderName: "hogehoge",
        comment: "いつも洗濯してくれてありがとう！ふかふかで気持ちいいです"
    )
    .padding(.space16)
}

#Preview("HouseworkDetailThanksCard_メッセージなし", traits: .sizeThatFitsLayout) {
    HouseworkDetailThanksCard(senderName: "hogehoge", comment: "")
        .padding(.space16)
}
#endif
