//
//  ImplAnalyticsClient.swift
//

import FirebaseAnalytics
import FirebaseCrashlytics
import HometeDomain

extension AnalyticsClient {

    static let liveValue: AnalyticsClient = .init { userId in
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
    } setUserProperty: { property in
        Analytics.setUserProperty(property.value, forName: property.name)
    } log: { event in
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

}
