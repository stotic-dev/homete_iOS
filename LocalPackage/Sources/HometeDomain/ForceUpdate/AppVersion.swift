//
//  AppVersion.swift
//  LocalPackage
//

import Foundation

/// `1.4.0`のようなドット区切りのバージョン
///
/// 各桁を数値として比べるため、`1.10.0`は`1.9.0`より新しい。桁数が違う場合は足りない桁を0とみなす（`1.4`と`1.4.0`は等しい）。
public struct AppVersion: Comparable, Sendable {

    private let components: [Int]

    /// - Returns: 空文字、数字以外を含む、空の桁がある（`1..0`など）場合は`nil`
    public init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var components: [Int] = []
        for component in trimmed.split(separator: ".", omittingEmptySubsequences: false) {
            // `Int("+1")`も通ってしまうため、ASCIIの数字だけで構成されていることを先に確かめる
            guard !component.isEmpty,
                  component.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let number = Int(component) else { return nil }
            components.append(number)
        }
        self.components = components
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) == 0
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compare(lhs, rhs) < 0
    }

}

private extension AppVersion {

    /// - Returns: `lhs`が古ければ負、新しければ正、等しければ0
    static func compare(_ lhs: AppVersion, _ rhs: AppVersion) -> Int {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0 ..< count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right {
                return left < right ? -1 : 1
            }
        }
        return 0
    }

}
