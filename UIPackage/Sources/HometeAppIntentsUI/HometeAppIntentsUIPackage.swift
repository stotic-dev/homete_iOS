//
//  HometeAppIntentsUIPackage.swift
//  LocalPackage
//

import AppIntents
import HometeAppIntents

/// 結果をSwiftUIで描くApp Intentのパッケージ。アプリ本体は、ここから`HometeAppIntentsPackage`のIntentもまとめて取り込む
public struct HometeAppIntentsUIPackage: AppIntentsPackage {

    public static var includedPackages: [any AppIntentsPackage.Type] {
        [HometeAppIntentsPackage.self]
    }

}
