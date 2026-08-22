//
//  OnTapAppAlreadySelectedTabItemModifier.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/08/22.
//

import HometeDomain
import SwiftUI

struct OnTapAppAlreadySelectedTabItemModifier: ViewModifier {

    let onTapAction: (_ type: TabType) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .onTapAppAlreadySelectedTabItem)) { output in
                guard let userInfo = output.userInfo,
                      let value = OnTapAppAlreadySelectedTabItemContext.parseValue(from: userInfo) else { return }
                onTapAction(value)
            }
    }

}

public extension View {

    /// すでに選択済みのタブをタップされた時の実行される処理
    func onTapAppTabItem(_ action: @escaping (TabType) -> Void) -> some View {
        modifier(OnTapAppAlreadySelectedTabItemModifier(onTapAction: action))
    }

}

public extension Notification.Name {

    /// すでに選択済みのタブをタップされた時の通知
    static let onTapAppAlreadySelectedTabItem: Notification.Name = .init("onTapAppAlreadySelectedTabItem")

}

public struct OnTapAppAlreadySelectedTabItemContext {

    let value: TabType

    public static func makeUserInfo(from value: TabType) -> [AnyHashable: TabType] {
        ["value": value]
    }

    static func parseValue(from userInfo: [AnyHashable: Any]) -> TabType? {
        OnTapAppAlreadySelectedTabItemContext(userInfo)?.value
    }

}

extension OnTapAppAlreadySelectedTabItemContext {

    init?(_ userInfo: [AnyHashable: Any]) {
        guard let value = userInfo["value"] as? TabType else { return nil }
        self.value = value
    }

}
