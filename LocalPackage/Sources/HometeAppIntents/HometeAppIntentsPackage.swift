//
//  HometeAppIntentsPackage.swift
//  LocalPackage
//

import AppIntents

/// このパッケージのApp Intentを、アプリのメタデータに含めるための宣言
///
/// アプリ側の`AppIntentsPackage`が`includedPackages`でこの型を挙げると、ビルド時にIntentのメタデータが抽出される。
public struct HometeAppIntentsPackage: AppIntentsPackage {}
