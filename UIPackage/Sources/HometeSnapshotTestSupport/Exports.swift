//
//  Exports.swift
//

// VRT（hometeSnapshotTests）が使うライブラリをLocalPackage経由で提供する。
// xcodeprojから直接参照すると、バージョンの指定がPackage.swiftと二重になり、
// dependabotが片方だけ更新したときに依存解決が失敗するため。
#if os(iOS)
@_exported import Prefire
@_exported import SnapshotTesting
#endif
