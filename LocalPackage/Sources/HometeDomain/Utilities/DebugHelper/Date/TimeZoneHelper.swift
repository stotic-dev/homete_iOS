//
//  TimeZoneHelper.swift
//  homete
//
//  Created by Taichi Sato on 2026/01/17.
//

import Foundation

#if DEBUG

extension TimeZone {
    // swiftlint:disable:next force_unwrapping
    public static let tokyo = Self.init(identifier: "Asia/Tokyo")!
}

#endif
