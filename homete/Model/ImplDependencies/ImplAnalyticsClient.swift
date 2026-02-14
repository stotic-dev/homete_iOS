//
//  AnalyticsClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

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
