//
//  TimeZoneHelper.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/17.
//

import Foundation

#if DEBUG

    public extension TimeZone {

        // swiftlint:disable:next force_unwrapping
        static let tokyo = Self(identifier: "Asia/Tokyo")!

    }

#endif
