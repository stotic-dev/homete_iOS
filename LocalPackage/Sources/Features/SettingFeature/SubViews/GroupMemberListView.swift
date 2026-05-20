//
//  GroupMemberListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain
import HometeUI
import SwiftUI

struct GroupMemberListView: View {

    let members: [CohabitantMember]

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            sectionHeader
            sectionContent
        }
    }

}

// MARK: - UI定義

private extension GroupMemberListView {

    var sectionHeader: some View {
        HStack(spacing: .space8) {
            Image(systemName: "person.2.fill")
                .foregroundStyle(.onSurface)
            Text("グループメンバー")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Spacer()
        }
    }

    @ViewBuilder
    var sectionContent: some View {
        if members.isEmpty {
            emptyContent
        } else {
            membersContent
        }
    }

    var membersContent: some View {
        VStack(spacing: .zero) {
            ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                GroupMemberRow(member: member)
                if index < members.count - 1 {
                    Divider()
                        .padding(.leading, .space16)
                }
            }
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space8)
        .background(.subSurface)
        .cornerRadius(.radius16)
    }

    var emptyContent: some View {
        Text("一緒に家事をするメンバーはまだいません")
            .font(with: .body)
            .foregroundStyle(.onSubSurface)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
            .background(.subSurface)
            .cornerRadius(.radius16)
    }

}

// MARK: - Preview定義

#Preview("GroupMemberListView_複数件", traits: .sizeThatFitsLayout) {
    GroupMemberListView(members: [
        .init(id: "user1", userName: "山田太郎"),
        .init(id: "user2", userName: "佐藤花子"),
        .init(id: "user3", userName: "田中次郎"),
    ])
    .padding(.space16)
}

#Preview("GroupMemberListView_1件", traits: .sizeThatFitsLayout) {
    GroupMemberListView(members: [
        .init(id: "user1", userName: "山田太郎"),
    ])
    .padding(.space16)
}

#Preview("GroupMemberListView_0件", traits: .sizeThatFitsLayout) {
    GroupMemberListView(members: [])
        .padding(.space16)
}
