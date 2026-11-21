//
//  ImplErrorReportClient.swift
//

import FirebaseCrashlytics
import HometeDomain
import HometeDomainUI

extension ErrorReportClient {

    static let liveValue: ErrorReportClient = .init { error, context in
        Crashlytics.crashlytics().record(error: error, userInfo: context)
    }

}
