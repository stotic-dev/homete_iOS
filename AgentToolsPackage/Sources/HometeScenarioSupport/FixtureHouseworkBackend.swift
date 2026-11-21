//
//  FixtureHouseworkBackend.swift
//  AgentToolsPackage
//

import Foundation
import HometeDomain

/// シナリオごとに独立した、家事の保存先
///
/// `HouseworkClient`の境界で、保存した家事を手元に持ち、書き込みの失敗を制御する。
/// プロセスごと・シナリオごとに作り直すので、起動をまたいで残らない。
public actor FixtureHouseworkBackend {

    /// 保存している家事
    public private(set) var items: [HouseworkItem]
    /// 書き込みを失敗させる残りの回数
    private var remainingWriteFailures: Int

    public init(items: [HouseworkItem], writeFailures: Int = 0) {
        self.items = items
        remainingWriteFailures = writeFailures
    }

    /// この保存先を使う`HouseworkClient`
    public nonisolated var client: HouseworkClient {
        HouseworkClient(
            insertOrUpdateItemHandler: { item, _ in
                try await self.write([item])
            },
            insertOrUpdateItemsHandler: { items, _ in
                try await self.write(items)
            },
            fetchItemsHandler: { _, _, _ in
                await self.items
            }
        )
    }

}

private extension FixtureHouseworkBackend {

    func write(_ written: [HouseworkItem]) throws {
        if remainingWriteFailures > 0 {
            remainingWriteFailures -= 1
            throw DomainError.noNetwork
        }
        for item in written {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            } else {
                items.append(item)
            }
        }
    }

}
