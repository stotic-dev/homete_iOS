//
//  RouteResolverInjection.swift
//  homete
//

import HometeDomain
import HometeUI
import SwiftUI

private struct RouteResolverInjectionModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .environment(\.routeResolver, RouteResolver { route in
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
            })
    }
}

extension View {

    func routeResolverInjection() -> some View {
        modifier(RouteResolverInjectionModifier())
    }
}
