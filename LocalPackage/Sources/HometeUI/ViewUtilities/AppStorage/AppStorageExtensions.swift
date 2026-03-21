//
//  AppStorageExtensions.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import SwiftUI

// MARK: - Data型の拡張

public extension SwiftUI.AppStorage where Value == Data? {

    init(key: AppStorageOptionalDataKey) {

        self.init(key.rawValue)
    }
}

public enum AppStorageOptionalDataKey: String {

    /// アーカイブされたP2P通信での自身のID
    case archivedPeerIDDataKey
}

// MARK: - カスタムオブジェクト用の拡張

public extension SwiftUI.AppStorage where Value: RawRepresentable, Value.RawValue == String {

    init(wrappedValue: Value, key: AppStorageCustomTypeKey) {

        self.init(wrappedValue: wrappedValue, key.rawValue)
    }
}

public enum AppStorageCustomTypeKey: String {

    /// 家事入力の履歴
    case houseworkEntryHistoryList
}

// MARK: - Preview用のDIヘルパー

public struct InjectAppStorageWithPreviewModifier: ViewModifier {
    private let userDefaults: UserDefaults

    public init(_ suiteName: String, _ registerHandler: @escaping (UserDefaults) -> Void) {

        // swiftlint:disable:next force_unwrapping
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        registerHandler(userDefaults)
    }

    public func body(content: Content) -> some View {
        content
            .defaultAppStorage(userDefaults)
    }
}

public extension View {

    func injectAppStorageWithPreview(
        _ suiteName: String,
        registerHandler: @escaping (UserDefaults) -> Void = { _ in }
    ) -> some View {
        self.modifier(InjectAppStorageWithPreviewModifier(suiteName, registerHandler))
    }
}
