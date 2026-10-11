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
            PedestalIcon(systemName: "person.circle.fill")
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
