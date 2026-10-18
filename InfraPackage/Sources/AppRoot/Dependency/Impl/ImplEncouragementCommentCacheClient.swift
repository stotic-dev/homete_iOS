//
//  ImplEncouragementCommentCacheClient.swift
//

import Foundation
import HometeDomain

extension EncouragementCommentCacheClient {

    /// 1件だけを`UserDefaults`にJSONで保存する
    ///
    /// 読み出せない（形式が変わった・壊れた）場合は保存していないものとして扱い、次の節目で生成し直す。
    static let liveValue: EncouragementCommentCacheClient = .init(
        load: {
            guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }

            return try? JSONDecoder().decode(EncouragementCommentCache.self, from: data)
        },
        save: { cache in
            guard let data = try? JSONEncoder().encode(cache) else { return }

            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    )

}

private extension EncouragementCommentCacheClient {

    static let cacheKey = "encouragementCommentCache"

}
