//
//  PendingEntry+RegisterSource.swift
//  LocalPackage
//

public extension PendingEntry {

    /// Analyticsの`source`に載せる入力元
    var registerSource: HouseworkRegisterSource {
        switch source {
        case .frequent:
            .frequent

        case .queued, .editing:
            .manual
        }
    }

}
