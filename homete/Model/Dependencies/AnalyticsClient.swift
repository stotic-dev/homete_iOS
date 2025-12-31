//
//  AnalyticsClient.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

import FirebaseAnalytics
import FirebaseCrashlytics

struct AnalyticsClient {
    
    let setId: @Sendable (String) -> Void
    let log: @Sendable (AnalyticsEvent) -> Void
    
    init(
        setId: @Sendable @escaping (String) -> Void = { _ in },
        log: @Sendable @escaping (AnalyticsEvent) -> Void = { _ in }
    ) {
        
        self.setId = setId
        self.log = log
    }
}

extension AnalyticsClient: DependencyClient {
    
    static let liveValue: AnalyticsClient = .init { userId in
        
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
    } log: { event in
        
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    static let previewValue = AnalyticsClient()
}
