//
//  HouseworkRetentionSyncState.swift
//  LocalPackage
//

import Foundation

/// 家事データの保持期限をどの状態まで同期済みかを表す
struct HouseworkRetentionSyncState: Equatable, Codable {

    let cohabitantId: String
    let isPremium: Bool

}

/// `HouseworkRetentionSyncState`を端末に永続化するストア
///
/// 保持期限の同期は、グループ未参加の間や通信失敗時にスキップされる。
/// スキップしたことを`Account.isPremium`の更新有無から判別することはできないため、
/// 同期の完了状態をアカウントとは独立して記録し、未完了なら次の機会にやり直せるようにする。
struct HouseworkRetentionSyncStateStore {

    private static let storageKey = "houseworkRetentionSyncState"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> HouseworkRetentionSyncState? {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return nil }

        return try? JSONDecoder().decode(HouseworkRetentionSyncState.self, from: data)
    }

    func save(_ state: HouseworkRetentionSyncState) {
        guard let data = try? JSONEncoder().encode(state) else { return }

        userDefaults.set(data, forKey: Self.storageKey)
    }

}
