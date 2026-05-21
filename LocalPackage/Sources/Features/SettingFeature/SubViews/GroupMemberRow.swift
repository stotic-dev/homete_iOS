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
                .foregroundStyle(.onSurface)
                .background(.primary3)
                .cornerRadius(.radius8)
            Text(member.userName)
                .font(with: .body)
            Spacer()
        }
        .foregroundStyle(.onSurface)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space8)
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    GroupMemberRow(member: .init(id: "user1", userName: "山田太郎"))
}
