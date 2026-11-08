//
//  HouseworkImageCache.swift
//

import Foundation

/// 家事に添えた画像を、端末のキャッシュに残す
///
/// 画像は保存先ごとに内容が変わらない（差し替えずに別の保存先へ上げる）ため、一度取得した画像は期限なく使い回せる。
/// 置き場所はOSが容量不足のときに消せるキャッシュのフォルダにし、消えていたら取り直す。
/// 家事の保持期限を過ぎた画像も残りうるが、端末内だけのもので、OSの判断で消える。
public actor HouseworkImageCache {

    public static let shared = HouseworkImageCache()

    private let fileManager = FileManager.default
    private let directory: URL
    /// 同じ画面の中で何度も読み込み直さないよう、最近使った画像はメモリにも持つ。1枚が最大2MBなので、件数ではなく容量で抑える
    private let memory = NSCache<NSString, NSData>()

    init() {
        directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "HouseworkImages", directoryHint: .isDirectory)
        memory.totalCostLimit = 20 * 1024 * 1024
    }

    /// キャッシュにある画像を返す。無ければ`nil`
    public func data(for storagePath: String) -> Data? {
        let key = storagePath as NSString
        if let data = memory.object(forKey: key) {
            return data as Data
        }
        guard let data = try? Data(contentsOf: fileURL(for: storagePath)) else { return nil }
        memory.setObject(data as NSData, forKey: key, cost: data.count)
        return data
    }

    /// 画像をキャッシュに残す。書き込みに失敗しても、次に取得し直すだけなので無視する
    public func store(_ data: Data, for storagePath: String) {
        memory.setObject(data as NSData, forKey: storagePath as NSString, cost: data.count)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL(for: storagePath), options: .atomic)
        } catch {
            print("Failed caching housework image \(storagePath): \(error)")
        }
    }

    /// 画像をキャッシュから消す
    public func remove(for storagePath: String) {
        memory.removeObject(forKey: storagePath as NSString)
        try? fileManager.removeItem(at: fileURL(for: storagePath))
    }

    /// 残した画像をすべて消す
    public func removeAll() {
        memory.removeAllObjects()
        try? fileManager.removeItem(at: directory)
    }

}

private extension HouseworkImageCache {

    /// 保存先のパスの区切りをファイル名に使える文字に置き換えて、1つのフォルダに並べる
    func fileURL(for storagePath: String) -> URL {
        directory.appending(path: storagePath.replacingOccurrences(of: "/", with: "_"), directoryHint: .notDirectory)
    }

}
