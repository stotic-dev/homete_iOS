//
//  Sequence+SkippingFailures.swift
//  LocalPackage
//

public extension Sequence {

    /// 要素ごとに変換し、変換に失敗した要素は結果から外す
    ///
    /// 1件の失敗で全体を失敗させたくないときに使う（例: 別バージョンのアプリが書いた形式の違うドキュメントが
    /// 混ざりうるFirestoreの一括取得）。外した要素は`onFailure`で受け取り、原因を追えるようにする。
    func compactMapSkippingFailures<T>(
        transform: (Element) throws -> T,
        onFailure: (Element, any Error) -> Void
    ) -> [T] {
        compactMap { element in
            do {
                return try transform(element)
            } catch {
                onFailure(element, error)
                return nil
            }
        }
    }

}
