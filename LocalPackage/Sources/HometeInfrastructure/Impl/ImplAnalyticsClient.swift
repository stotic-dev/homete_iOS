//
//  ImplAnalyticsClient.swift
//

#if os(iOS)
    import FirebaseAnalytics
    import FirebaseCrashlytics
    import HometeDomain

    extension AnalyticsClient {

        static let liveValue: AnalyticsClient = .init { userId in
            Analytics.setUserID(userId)
            Crashlytics.crashlytics().setUserID(userId)
        } log: { event in
            Analytics.logEvent(event.name, parameters: event.parameters)
        }

    }
#endif
