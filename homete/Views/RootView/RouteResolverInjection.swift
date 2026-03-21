//
//  RouteResolverInjection.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

extension EnvironmentValues {
    @Entry var routeResolver = RouteResolver { route in
        switch route {
        case .houseworkDetail(let item):
            HouseworkDetailView(item: item)
        case .houseworkApproval(let item):
            HouseworkApprovalView(item: item)
        case .cohabitantRegistration:
            CohabitantRegistrationView()
        case .setting:
            SettingView()
        }
    }
}
