//
//  ImplAppReviewStateClient.swift
//

import Foundation
import HometeDomain

public extension AppReviewStateClient {

    static let liveValue: AppReviewStateClient = .init {
        guard let data = UserDefaults.standard.data(forKey: Self.stateKey) else { return nil }

        do {
            return try JSONDecoder().decode(AppReviewState.self, from: data)
        } catch {
            print("failed to decode app review state: \(error)")
            return nil
        }
    } save: { state in
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: Self.stateKey)
        } catch {
            print("failed to encode app review state: \(error)")
        }
    }

}

private extension AppReviewStateClient {

    static let stateKey = "appReviewState"

}
