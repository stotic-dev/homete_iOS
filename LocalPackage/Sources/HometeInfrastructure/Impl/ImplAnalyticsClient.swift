//
//  ImplAnalyticsClient.swift
//

import HometeDomain
import FirebaseAnalytics
import FirebaseCrashlytics

extension AnalyticsClient {

    static let liveValue: AnalyticsClient = .init { userId in

        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
    } log: { event in

        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
