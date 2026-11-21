//
//  CohabitantMembers+Environment.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

public extension EnvironmentValues {

    /// 家事グループメンバー
    @Entry var cohabitantMembers: CohabitantMemberList = .init(value: [], ownId: "")

}
