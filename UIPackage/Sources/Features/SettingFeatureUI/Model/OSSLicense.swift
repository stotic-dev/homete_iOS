//
//  OSSLicense.swift
//  homete
//

import HometeModel

public struct OSSLicense: Identifiable, Hashable, Sendable {

    public let id: String
    public let name: String
    public let licenseType: String
    public let licenseText: String

    public init(
        id: String,
        name: String,
        licenseType: String,
        licenseText: String
    ) {
        self.id = id
        self.name = name
        self.licenseType = licenseType
        self.licenseText = licenseText
    }

}

public extension OSSLicense {

    static let all: [OSSLicense] = [
        .init(
            id: "firebase-ios-sdk",
            name: "Firebase iOS SDK",
            licenseType: "Apache License 2.0",
            licenseText: .apacheLicense2_0
        ),
        .init(
            id: "purchases-ios-spm",
            name: "RevenueCat",
            licenseType: "MIT License",
            licenseText: .revenueCatMitLicense
        ),
        .init(
            id: "swift-package-manager-google-mobile-ads",
            name: "Google Mobile Ads SDK",
            licenseType: "Apache License 2.0",
            licenseText: .apacheLicense2_0
        ),
        .init(
            id: "swift-package-manager-google-user-messaging-platform",
            name: "Google User Messaging Platform",
            licenseType: "Apache License 2.0",
            licenseText: .apacheLicense2_0
        ),
        .init(
            id: "prefire",
            name: "Prefire",
            licenseType: "Apache License 2.0",
            licenseText: .apacheLicense2_0
        ),
    ]

}
