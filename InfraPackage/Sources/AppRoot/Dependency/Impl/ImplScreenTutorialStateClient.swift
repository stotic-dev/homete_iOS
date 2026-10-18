//
//  ImplScreenTutorialStateClient.swift
//

import Foundation
import HometeDomain

public extension ScreenTutorialStateClient {

    static let liveValue: ScreenTutorialStateClient = .init { screen in
        UserDefaults.standard.bool(forKey: Self.hasSeenKey(screen))
    } saveHasSeen: { screen, hasSeen in
        UserDefaults.standard.set(hasSeen, forKey: Self.hasSeenKey(screen))
    }

}

private extension ScreenTutorialStateClient {

    /// 未設定時は`false`が返るため、アップデート前から使っている既存のユーザーにも一度出る
    static func hasSeenKey(_ screen: ScreenTutorial) -> String {
        "hasSeenScreenTutorial_\(screen.rawValue)"
    }

}
