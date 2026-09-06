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
    } clearId: {
        Analytics.setUserID(nil)
        Crashlytics.crashlytics().setUserID(nil)
    } setUserProperty: { property in
        Analytics.setUserProperty(property.value, forName: property.name)
    } log: { event in
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

}
