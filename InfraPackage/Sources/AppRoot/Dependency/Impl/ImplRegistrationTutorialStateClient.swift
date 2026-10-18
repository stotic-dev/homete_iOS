//
//  ImplRegistrationTutorialStateClient.swift
//

import Foundation
import HometeDomain

public extension RegistrationTutorialStateClient {

    static let liveValue: RegistrationTutorialStateClient = .init {
        UserDefaults.standard.bool(forKey: Self.isPendingKey)
    } saveIsPending: {
        UserDefaults.standard.set($0, forKey: Self.isPendingKey)
    }

}

private extension RegistrationTutorialStateClient {

    /// 未設定時は`false`が返るため、グループ登録を経ていない既存のユーザーにはチュートリアルが出ない
    static let isPendingKey = "isPendingRegistrationTutorial"

}
