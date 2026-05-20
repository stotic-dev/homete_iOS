//
//  GroupMemberListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct GroupMemberListView: View {

    let members: [CohabitantMember]

    public init(members: [CohabitantMember]) {
        self.members = members
    }

    public var body: some View {
        VStack(spacing: .zero) {
            ForEach(members, id: \.id) { member in
                GroupMemberRow(member: member)
            }
        }
    }

}

#if DEBUG
    #Preview("複数件", traits: .sizeThatFitsLayout) {
        GroupMemberListView(members: [
            .init(id: "user1", userName: "山田太郎"),
            .init(id: "user2", userName: "佐藤花子"),
            .init(id: "user3", userName: "田中次郎"),
        ])
    }

    #Preview("1件", traits: .sizeThatFitsLayout) {
        GroupMemberListView(members: [
            .init(id: "user1", userName: "山田太郎"),
        ])
    }

    #Preview("0件", traits: .sizeThatFitsLayout) {
        GroupMemberListView(members: [])
    }
#endif
