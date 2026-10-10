//
//  GroupMemberRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct GroupMemberRow: View {

    let member: CohabitantMember

    public init(member: CohabitantMember) {
        self.member = member
    }

    public var body: some View {
        HStack(spacing: .space16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.space8)
                .foregroundStyle(.textPrimary)
                .background(.fillAccentSubtle)
                .cornerRadius(.radius12)
            Text(member.userName)
                .font(with: .body)
            Spacer()
        }
        .foregroundStyle(.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space8)
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    GroupMemberRow(member: .init(id: "user1", userName: "山田太郎"))
}
