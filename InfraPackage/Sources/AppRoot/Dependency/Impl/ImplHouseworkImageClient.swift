//
//  ImplHouseworkImageClient.swift
//

import HometeDomain
import HometeDomainUI
import HometeInfrastructure

extension HouseworkImageClient {

    static let liveValue = HometeDomain.HouseworkImageClient(
        upload: { data, storagePath in
            try await StorageService.uploadJPEG(data, path: storagePath)
            // 上げた人の端末では、上げた画像をそのまま表示に使い、取り直さない
            await HouseworkImageCache.shared.store(data, for: storagePath)
        },
        delete: { storagePath in
            // 参照はもう無いので、Storageから消せなくても端末からは消す（消せなかった実体は、家事が消えるときにまとめて消す）
            await HouseworkImageCache.shared.remove(for: storagePath)
            try await StorageService.delete(path: storagePath)
        },
        fetch: { storagePath in
            if let cached = await HouseworkImageCache.shared.data(for: storagePath) {
                return cached
            }
            let data = try await StorageService.data(path: storagePath)
            await HouseworkImageCache.shared.store(data, for: storagePath)
            return data
        },
        clearCache: {
            await HouseworkImageCache.shared.removeAll()
        }
    )

}
